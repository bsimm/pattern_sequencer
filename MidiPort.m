//
//  MidiPort.m
//  PatternSequencer
//
//  Created by Sebastian Lederer on Tue Aug 12 2003.
/*
 Copyright (c) 2003-2010 Sebastian Lederer
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "MidiPort.h"

#include "debug.h"

@implementation MidiPort

static     MIDIClientRef 	midiClient;
static int nullPortIndex;
static BOOL ReceiveClocks;
static BOOL ReceiveChannelData=NO;

static MIDIPacketList *ClockPacket;

static void midiReadProc(const MIDIPacketList *pktlist, void *refCon, void *srcRefCon)
{
    id port=refCon;
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;	// remove const (!)
    int i,j;

    if(refCon==NULL) fprintf(stderr,"refCon==NULL\n");

    for (j = 0; j < pktlist->numPackets; ++j)
    {
    
    
        if(ReceiveClocks)
        {
            for (i = 0; i < packet->length; ++i)
            {
        //
        // handle realtime messages
        //
            
                switch(packet->data[i])
                {
                    case 0xf8:  // clock
                        [ port clockTick ];
                        break;
                    case 0xfa:  // start
                        [ port realtimeReceived: RealtimeStart ];
                        break;
                    case 0xfb: // continue
                        [ port realtimeReceived: RealtimeContinue ];
                        break;
                    case 0xfc: // stop
                        [ port realtimeReceived: RealtimeStop ];
                        break;
                    default:
                        break;
                }
            }
        }
        
        if(ReceiveChannelData)
        {
            [ port packetReceived: packet ];        
        }
        
         // printf("\n");
	packet = MIDIPacketNext(packet);
    }
}

+ (void) initialize
{
    static Byte buffer[1024];
    Byte clock=0xf8;
    MIDIPacket *packet;
    
    ClockPacket=(MIDIPacketList *) buffer;
    packet = MIDIPacketListInit(ClockPacket);
    packet=MIDIPacketListAdd(ClockPacket,sizeof(buffer),
                packet, 0, sizeof(clock), &clock);   

}

+ defaultPort
{
    return [ self port: 0 ];
}

+ (NSArray *) availablePorts
{
    int n,i;
    MIDIEndpointRef	midi;
    CFStringRef pname,pmodel;
    char name[64],model[64];
    id array;
    id str;

    array=[[ NSMutableArray alloc ] init ];

    n = MIDIGetNumberOfDestinations();    
    for(i=0; i<n; i++)
    {
        midi = MIDIGetDestination(i);
    
        if (midi != NULL) {
                strcpy(name,"<none>");
                strcpy(model,"<none>");

                if(MIDIObjectGetStringProperty(midi, kMIDIPropertyName, &pname)==0)
                {
                    CFStringGetCString(pname, name, sizeof(name), 0);
                    CFRelease(pname);
                }

                if(MIDIObjectGetStringProperty(midi, kMIDIPropertyModel, &pmodel)==0)
                {
                    CFStringGetCString(pmodel, model, sizeof(model), 0);
                    CFRelease(pmodel);
                    //dbgprintf("Destination: %s (%s)\n", name, model);
                }
        }
        
        str=[ NSString stringWithFormat: @"%s (%s)", model, name ];
        [ array addObject: str ];
    }

    // add a dummy port to the list
    [ array addObject: @"None" ];

    [ array autorelease ];
    return array;
}

+ (NSArray *) availableInputPorts
{
    int n,i;
    MIDIEndpointRef	midi;
    CFStringRef pname,pmodel;
    char name[64],model[64];
    id array;
    id str;

    array=[[ NSMutableArray alloc ] init ];

    n = MIDIGetNumberOfSources();    
    for(i=0; i<n; i++)
    {
        midi = MIDIGetSource(i);
    
        if (midi != NULL) {
                strcpy(name,"<none>");
                strcpy(model,"<none>");

                if(MIDIObjectGetStringProperty(midi, kMIDIPropertyName, &pname)==0)
                {
                    CFStringGetCString(pname, name, sizeof(name), 0);
                    CFRelease(pname);
                }

                if(MIDIObjectGetStringProperty(midi, kMIDIPropertyModel, &pmodel)==0)
                {
                    CFStringGetCString(pmodel, model, sizeof(model), 0);
                    CFRelease(pmodel);
                    dbgprintf("Source: %s (%s)\n", name, model);
                }
        }
        
        str=[ NSString stringWithFormat: @"%s (%s)", model, name ];
        [ array addObject: str ];
    }

    // add a dummy port to the list
    [ array addObject: @"None" ];

    [ array autorelease ];
    return array;
}

+ port: (int) index
{
    id newPort=[[ self alloc ] init ];
    [ newPort openPort: index ];
    [ newPort autorelease ];
    return newPort;
}

+ inputPort: (int) index
{
    id newPort=[[ self alloc ] init ];
    [ newPort openInputPort: index ];
    [ newPort autorelease ];
    return newPort;
}

+ (void) initMidiClient
{
    if(midiClient!=NULL) return;
    
    MIDIClientCreate(CFSTR("PatternSequencer"), NULL, NULL, &midiClient);
    if(midiClient==NULL) fprintf(stderr,"MIDIClientCreate failed\n");    
    nullPortIndex=MIDIGetNumberOfDevices();
}

+ (void) shutdownMidiClient
{
    MIDIClientDispose(midiClient);
}

- init
{
    int i;
    MIDIPacketList *p;
    
    for(i=0;i<NUMBER_OF_QUEUES;i++)
    {
        p=(MIDIPacketList *) malloc(QUEUE_SIZE);
        if(!p) return nil;
        
        queues[i].clock=0;
        queues[i].packetList=p;
        queues[i].packet=MIDIPacketListInit(p);
    }
    
    clocksPerStep=6;
    lock=[[ NSLock alloc ] init ];
    return self;
}

- (void) dealloc
{
    int i;

    for(i=0;i<NUMBER_OF_QUEUES;i++) free(queues[i].packetList);

    MIDIPortDispose(outPort);
    MIDIPortDispose(inPort);
    
    [ sequencer release ];
    [ lock release ];
    [ super dealloc ];
}

- (void) packetReceived: (MIDIPacket *) packet
{
    NSAutoreleasePool *pool=nil;
    int i=0;

    if(packet->length<3) return;
    
    //printf("0x%2x ", (int) packet->data[i]);
    
    switch(packet->data[i] & 0xf0)
    {
        case 0x90:  // Note on
            dbgprintf("NoteOn key: %d velocity %d\n",(int) packet->data[i+1], (int) packet->data[i+2]);
            if(inputBuffer)
            {
                pool=[[ NSAutoreleasePool alloc ] init ];
                
                // report noteOn with zero velocity as noteOff
                if(packet->data[i+2]>0)
                {
                    [ inputBuffer noteOnReceived: packet->data[i+1]
                                        velocity: packet->data[i+2]
                                              at: packet->timeStamp ];
                }
                else
                {
                    [ inputBuffer noteOffReceived: packet->data[i+1]
                                         velocity: packet->data[i+2]
                                               at: packet->timeStamp ];
                }
            }
            break;
        case 0x80:  // Note off
            dbgprintf("NoteOff key: %d velocity %d\n",(int) packet->data[i+1], (int) packet->data[i+2]);
            if(inputBuffer)
            {
                pool=[[ NSAutoreleasePool alloc ] init ];
                [ inputBuffer noteOffReceived: packet->data[i+1]
                                    velocity: packet->data[i+2]
                                          at: packet->timeStamp ];
            }
            
            break;
        default:
            break;
    }
    
    if(midiThru) [ self queueEvent: packet->data size: packet->length atClock: 0 ];

    [ pool release ];
    
    if(packet->length>3) dbgprintf("packet length %d\n",packet->length);
}

- (void) realtimeReceived: (realtime_t) msg
{
    NSAutoreleasePool *pool;

    if(!externalClock) return;

    pool=[[ NSAutoreleasePool alloc ] init ];
    
    [ self realtimeControl: msg ];
    
    [ pool release ];
}

- realtimeControl: (realtime_t) msg
{
    clocksPerStep=24/[ sequencer stepsPerBeat ];

    switch(msg)
    {
        case RealtimeStart:
            currentClock=0;
            [ sequencer portStarted ];
            if(sendClocks) [ self sendRealtimeStartAt: 0 ];
            started=YES;
            break;
        case RealtimeContinue:
            if(sendClocks) [ self sendRealtimeContinueAt: 0 ];
            started=YES;
            break;
        case RealtimeStop:
            [ sequencer portStopped ];
            if(sendClocks) [ self sendRealtimeStopAt: 0 ];
            started=NO;
            break;
    }

    return self;
}

- (void) flushQueues
{
    struct MIDIPacketQueue *q;
    int i;
    
    for(i=0;i<NUMBER_OF_QUEUES;i++)
    {
        q=&queues[i];
        q->clock=0;
        q->packet=MIDIPacketListInit(q->packetList);
    }
    activeQueues=0;
}

- clockTick
{
    struct MIDIPacketQueue *q;
    int i;
    int activeCount;
    NSAutoreleasePool *pool;

    // this is run from the midi thread so we have to set up our own
    // autorelease pool
    // but only if we do any other message calls which might create autoreleased
    // objects

    if(!started) return self;

    if(sendClocks) MIDISend(outPort,dest,ClockPacket);

    [ lock lock ];

    q=&queues[nextQueueSlot];

    // send queue contents for this clock tick    
    if(q->clock==1)
    {
        MIDISend(outPort,dest,q->packetList);

        // reinitialize current queue slot
        q->clock=0;
        q->packet=MIDIPacketListInit(q->packetList);

        activeQueues--;
    }

    // decrease clocks and find the queue which is due at the next clock

    q=queues;
    activeCount=activeQueues;
    i=0;
    while(activeCount && i<NUMBER_OF_QUEUES)
    {
        if(q->clock>0)
        {
            q->clock--;
            if(q->clock==1) nextQueueSlot=i;
            activeCount--;
        }
        q++;
        i++;
    }

    [ lock unlock ];
    
    currentClock++;

    if(currentClock==clocksPerStep)
    {
        currentClock=0;
        pool=[[ NSAutoreleasePool alloc ] init ];
        [ sequencer tick: self ];
        [ pool release ];
    }
    return self;
}

- queueEvent: (Byte*) event size: (int) size atClock: (int) clock
{
    struct MIDIPacketQueue *q=queues;
    int i;
    MIDIPacketList *packetList;
    MIDIPacket *packet;
    Byte buffer[QUEUE_SIZE];
    
    // printf("queueEvent size:%d clock: %d activeQueues before:%d\n",size,clock,activeQueues);

    // should the event be send immediately? 
    if(clock==0)
    {
        packetList=(MIDIPacketList *) buffer;
        packet=MIDIPacketListInit(packetList);
        packet=MIDIPacketListAdd(packetList, sizeof(buffer),
                packet, 0, size, event);
        MIDISend(outPort,dest,packetList);
        return self;
    }
    
    // find queue slot with same clock value

    [ lock lock ];

    for(i=0;i<NUMBER_OF_QUEUES;i++)
    {
        if(q->clock==clock)
        {
            q->packet=MIDIPacketListAdd(q->packetList, QUEUE_SIZE,
                q->packet, 0, size, event);
            [ lock unlock ];
            return self;
        }
        
        q++;
    }
    
    // else find an empty slot
    
    q=queues;
    for(i=0;i<NUMBER_OF_QUEUES;i++)
    {
        if(q->clock==0)
        {
            q->clock=clock;
            q->packet=MIDIPacketListAdd(q->packetList, QUEUE_SIZE,
                q->packet, 0, size, event);
            activeQueues++;
            
            if(clock==1) nextQueueSlot=i;
            
            [ lock unlock ];
            return self;
        }
        q++;
    }
    
    [ lock unlock ];
    [ NSException raise: @"AppErrorException" format: @"cannot find empty queue slot" ];
    return nil;
}

- setInputBuffer: (InputBuffer *) newInputBuffer
{
    [ newInputBuffer retain ];
    [ inputBuffer release ];
    inputBuffer=newInputBuffer;
    
    ReceiveChannelData=(inputBuffer!=nil);

    return self;
}

- setSequencer: (Sequencer *) s
{
    [ s retain ];
    [ sequencer release ];
    sequencer=s;
    return self;
}

- setExternalClock: (BOOL) aBool
{
    externalClock=aBool;
    ReceiveClocks=aBool;
    started=NO;
        
    return self;
}

- setSendClocks: (BOOL) aBool
{
    sendClocks=aBool;
    return self;
}

- setMIDIThru: (BOOL) aBool
{
    midiThru=aBool;
    return self;
}

- (Sequencer *) sequencer
{
    return sequencer;
}

- (InputBuffer *) inputBuffer
{
    return inputBuffer;
}

- (void) test
{
    int i,n;
    CFStringRef pname, pmanuf, pmodel;
    char name[64], manuf[64], model[64];
    MIDIDeviceRef dev;   

    [[ self class ] initMidiClient ];

    n = MIDIGetNumberOfDevices();

    for (i = 0; i < n; ++i)
    {
            dev = MIDIGetDevice(i);
            
            MIDIObjectGetStringProperty(dev, kMIDIPropertyName, &pname);
            MIDIObjectGetStringProperty(dev, kMIDIPropertyManufacturer, &pmanuf);
            MIDIObjectGetStringProperty(dev, kMIDIPropertyModel, &pmodel);
            
            CFStringGetCString(pname, name, sizeof(name), 0);
            CFStringGetCString(pmanuf, manuf, sizeof(manuf), 0);
            CFStringGetCString(pmodel, model, sizeof(model), 0);
            CFRelease(pname);
            CFRelease(pmanuf);
            CFRelease(pmodel);

            dbgprintf("name=%s, manuf=%s, model=%s\n", name, manuf, model);
    }

    n = MIDIGetNumberOfDestinations();    
    for(i=0; i<n; i++)
    {
        dest = MIDIGetDestination(i);

        if (dest != NULL) {
                MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &pname);
                MIDIObjectGetStringProperty(dest, kMIDIPropertyModel, &pmodel);

                CFStringGetCString(pname, name, sizeof(name), 0);
                CFStringGetCString(pmodel, model, sizeof(model), 0);

                CFRelease(pname);
                CFRelease(pmodel);
                dbgprintf("Destination: %s %s\n", name, model);
        }
    }

}

- closeInputPort
{
    if(!inPort) return self;
    
    MIDIPortDispose(inPort);
    inPort=NULL;
    
    return self;
}

- openInputPort: (int) index
{
    int n;
    CFStringRef pname;
    char name[64];

    if(inPort!=NULL) return nil;

    [[ self class ] initMidiClient ];
    
    MIDIInputPortCreate(midiClient, CFSTR("pseq input port"), midiReadProc, self, &inPort);
    if(inPort==NULL) fprintf(stderr,"MIDIInputPortCreate failed\n");

    n = MIDIGetNumberOfSources();
    
    if (index==n) return self; // dummy port

    if (index>n) return nil;
    
    src = MIDIGetSource(index);
    MIDIPortConnectSource(inPort,src,NULL);

    if (src != NULL)
    {
        MIDIObjectGetStringProperty(src, kMIDIPropertyName, &pname);
        CFStringGetCString(pname, name, sizeof(name), 0);
        CFRelease(pname);
        dbgprintf("Opened source: %s\n", name);
    }
    else
    {
            dbgprintf("No MIDI sources present\n");
    }

    return nil;
}

- openPort: (int) index
{
    int n;
    CFStringRef pname;
    char name[64];

    if(outPort!=NULL) return nil;
    
    [[ self class ] initMidiClient ];

    MIDIOutputPortCreate(midiClient, CFSTR("pseq output port"), &outPort);
    if(outPort==NULL) fprintf(stderr,"MIDIOutputPortCreate failed\n");
    
    // find the first destination
    n = MIDIGetNumberOfDestinations();

    if (index==n) return self; // dummy port

    if (index>n) return nil;

    dest = MIDIGetDestination(index);

    if (dest != NULL)
    {
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &pname);
        CFStringGetCString(pname, name, sizeof(name), 0);
        CFRelease(pname);
        dbgprintf("Opened destination: %s\n", name);
    }
    else
    {
            dbgprintf("No MIDI destinations present\n");
    }
    
    // [ self sendInquiry ];
    
    return self;
}

//- (void) sendInquiry
//{
//    Byte inquiry[]={ 0xf0,0x7e,0x00,0x06,0x01,0xf7 };
//    
//    [ self queueMIDIEvent: inquiry size: sizeof(inquiry) at: 0 ];
//}

- queueMIDIEvent: (Byte *) bytes size: (int) sz at: (MIDITimeStamp) time
{
    Byte buffer[1024];
    
    if(!outPort) return self;
    
    MIDIPacketList *packetList = (MIDIPacketList *) buffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    
    packet=MIDIPacketListAdd(packetList, sizeof(buffer),
            packet, time, sz,
            bytes);

    MIDISend(outPort,dest,packetList);

    return self;
}

- sendRealtimeStartAt: (MIDITimeStamp) time
{
    Byte start=0xfa;
    return [ self queueMIDIEvent: &start size: 1 at: time ];
}

- sendRealtimeStopAt: (MIDITimeStamp) time
{
    Byte stop=0xfc;
    return [ self queueMIDIEvent: &stop size: 1 at: time ];    
}

- sendRealtimeContinueAt: (MIDITimeStamp) time
{
    Byte c=0xfb;
    return [ self queueMIDIEvent: &c size: 1 at: time ];    
}
- sendSongPosition: (int) position at: (MIDITimeStamp) time
{
    Byte buffer[3];
    
    buffer[0]=0xf2;
    buffer[1]=position & 0x7f;
    buffer[2]=(position >> 7) & 0x7f;
    
    return [ self queueMIDIEvent: buffer size: 3 at: time ];
}

- sendMIDIClocks: (int) amount at: (MIDITimeStamp) time tickLength: (unsigned long int) length
{
    Byte buffer[1024];
    Byte clock=0xf8;
    MIDIPacketList *packetList= (MIDIPacketList *) buffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    int i;
    
    for(i=0;i<amount;i++)
    {
        packet=MIDIPacketListAdd(packetList,sizeof(buffer),
                packet, time, 1, &clock);
        time += length;
    }

    MIDISend(outPort,dest,packetList);
    
    return self;
} 

- note: (int) anInt at: (unsigned long int) clock duration: (unsigned long int) length
    velocity: (int) vel on: (int) channel
{    
    Byte noteOn[] = { 0x90, 60, 100 };
    Byte noteOff[] = { 0x80, 60, 100 };
    
    channel = (channel-1) & 0xf;
    vel &= 0x7f;
    
    noteOn[0] |= channel;
    noteOn[1] = anInt;
    noteOn[2] = vel;

    noteOff[0] |= channel;
    noteOff[1] = anInt;
    noteOff[2] = vel;

    [ self queueEvent: noteOn size: sizeof(noteOn) atClock: clock ];
    [ self queueEvent: noteOff size: sizeof(noteOff) atClock: clock+length ];
    return self;
}

- note: (int) anInt atTime: (MIDITimeStamp) time duration: (unsigned long int) length
    velocity: (int) vel on: (int) channel
{    
    Byte buffer[1024];
    
    Byte noteOn[] = { 0x90, 60, 100 };
    Byte noteOff[] = { 0x80, 60, 100 };

    MIDIPacketList *packetList = (MIDIPacketList *) buffer;
    MIDIPacket *packet = MIDIPacketListInit(packetList);
    
    channel = (channel-1) & 0xf;
    vel &= 0x7f;
    
    noteOn[0] |= channel;
    noteOn[1] = anInt;
    noteOn[2] = vel;

    noteOff[0] |= channel;
    noteOff[1] = anInt;
    noteOff[2] = vel;
    
    packet=MIDIPacketListAdd(packetList, sizeof(buffer),
            packet, time, 3,
            noteOn);
    packet=MIDIPacketListAdd(packetList, sizeof(buffer),
            packet, time+length, 3,
            noteOff);

    MIDISend(outPort,dest,packetList);
    
    return self;
}


- selectProgram: (int) prog on: (int) channel at: (MIDITimeStamp) time
{
    Byte programChange[2];

    programChange[0]=0xc0 | ( (channel-1) & 0xf);
    programChange[1]=prog & 0x7f;
    
    return [ self queueEvent: programChange size: sizeof(programChange) atClock: time ];
}

- selectBank: (int) bank on: (int) channel
{
    int bankHi=0;
    int bankLo=bank;
    
    [ self sendController: 0 value: bankHi on: channel at: 0 ];
    return [ self sendController: 32 value: bankLo on: channel at: 0 ];
}

- changeVolume: (int) volume on: (int) channel
{
    if(volume<0 || volume>127) return nil;

    return [ self sendController: 7 value: volume on: channel at: 0 ];
}

- sendPitchBend: (int) value on: (int) channel at: (MIDITimeStamp) time
{
    Byte pitchBendMessage[3];
    
    pitchBendMessage[0]=0xe0 | ( (channel-1) & 0xf);
    pitchBendMessage[1]=value & 0x7f;
    pitchBendMessage[2]=(value >> 7) & 0x7f;
    
    return [ self queueEvent: pitchBendMessage
                size: sizeof(pitchBendMessage) atClock: time ];
}

- sendController: (int) cc value: (int) value on: (int) channel at: (MIDITimeStamp) time
{
    // if(cc>0x1f) return nil;
    
    Byte controllerMessage[3];
    
    controllerMessage[0]=0xb0 | ( (channel-1) & 0xf);
    controllerMessage[1]=cc & 0x7f;
    controllerMessage[2]=value & 0x7f;

    return [ self queueEvent: controllerMessage
        size: sizeof(controllerMessage) atClock: time ];
}

- allNotesOffOnChannel: (int) channel
{
    return [ self sendController: 0x7b value:0 on: channel at: 0 ];
}

- flush
{
    //MIDIFlushOutput(dest);
    [ self flushQueues ];
    return self;
}
@end
