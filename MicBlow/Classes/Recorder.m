//
//  Recorder.m
//  AudioRecordTest
//
//  Created by perun on 11-9-1.
//  Copyright 2011 __cn.perun__. All rights reserved.
//

#import "Recorder.h"
//the recording audio queue callback declaration
static void HandleInputBuffer(
                              void									*aqData,
                              AudioQueueRef							inAQ,
                              AudioQueueBufferRef						inBuffer,
                              const	AudioTimeStamp					*inStartTime,
                              UInt32									inNumPackets,
                              const	AudioStreamPacketDescription	*inPacketDesc
                              ){
#ifdef	DEBUG 
	printf("call input callback....\n");
#endif
	RecorderState *pAqData=(RecorderState *)aqData;
	
	if (inNumPackets>0) {
		//pAqData->inputBufferHandler((short int *)inBuffer->mAudioData,inBuffer->mAudioDataByteSize);
        id<RecordFilterDelegate> delegate=pAqData->filterDelegate;
        if(delegate&&[delegate respondsToSelector:@selector(filterRecordData:length:)])
            [delegate filterRecordData:(short int *)inBuffer->mAudioData 
                                length:inBuffer->mAudioDataByteSize];
#ifdef writeToFile
		//write an audio queue buffer to disk
		AudioFileWritePackets(
                              pAqData->mAudioFile, 
                              false, 
                              inBuffer->mAudioDataByteSize,
                              inPacketDesc,
                              pAqData->mCurrentPacket,
                              &inNumPackets, 
                              inBuffer->mAudioData
							  );
#endif
		pAqData->mCurrentPacket+=inNumPackets;
		//if record is stopped.
		if (pAqData->mIsRunning==0) 
			return;
		//Enqueuing an audio queue buffer after writing to disk
		AudioQueueEnqueueBuffer(pAqData->mQueue,
								inBuffer, 
								0,
								NULL);
	}
	
	
	
}
//deriving a recording audio queue buffer size
void	DeriveBufferSize(
                         AudioQueueRef				audioQueue,
                         AudioStreamBasicDescription	ASBDescription,
                         Float64						seconds,
                         UInt32						*outBufferSize
                         ){
	static const int maxBufferSize=0x50000;
	
	int maxPacketSize=ASBDescription.mBytesPerPacket;
	if (maxBufferSize==0) {
		UInt32 maxVBRPacketSize=sizeof(maxPacketSize);
		AudioQueueGetProperty(audioQueue,
							  kAudioQueueProperty_MaximumOutputPacketSize,
							  &maxPacketSize, 
							  &maxVBRPacketSize);
	}
	
	Float64 numBytesForTime=ASBDescription.mSampleRate*maxPacketSize*seconds;
	*outBufferSize=(UInt32)(numBytesForTime<maxBufferSize?numBytesForTime:maxBufferSize);
} 



#ifdef writeToFile
//Setting a magic cookie for an audio file
OSStatus SetMagicCookieForFile(
                               AudioQueueRef inQueue,
                               AudioFileID		inFile
                               ){
	OSStatus result=noErr;
	UInt32	cookieSize;
	if (AudioQueueGetPropertySize(inQueue, kAudioQueueProperty_MagicCookie, &cookieSize)==noErr) {
		char *magicCookie=(char *)malloc(cookieSize);
		if (
            AudioQueueGetProperty(inQueue, kAudioQueueProperty_MagicCookie,
                                  magicCookie, &cookieSize)==noErr
			) {
			result=AudioFileSetProperty(inFile,
										kAudioFilePropertyMagicCookieData,
										cookieSize, magicCookie);
			free(magicCookie);
		}
	}
	return result;
}
#endif


@implementation Recorder

//set up audio data format you want.
- (void)setUpAudioDataFormat:(AudioStreamBasicDescription *)format{
	format->mFormatID=kAudioFormatLinearPCM;
	//format->mSampleRate=44100.0;
    format->mSampleRate=16000.0;
	format->mChannelsPerFrame=1;
	format->mBitsPerChannel=16;
	format->mBytesPerPacket=
	format->mBytesPerFrame=format->mChannelsPerFrame*sizeof(SInt16);
	format->mFramesPerPacket=1;
	format->mFormatFlags=kLinearPCMFormatFlagIsSignedInteger
    |kLinearPCMFormatFlagIsPacked;
}
#ifdef writeToFile
- (BOOL)start:(NSString *)filePath filterDelegate:(id<RecordFilterDelegate>)delegate{
	recordState.filterDelegate=delegate;
	//Set up the audio format and the url to record
	[self setUpAudioDataFormat:&recordState.mDataFormat];
	
	CFURLRef fileURL=CFURLCreateFromFileSystemRepresentation(
                                                             NULL, (const UInt8 *)[filePath UTF8String],
                                                             [filePath length], NO);
	recordState.mCurrentPacket=0;
	
	//initialize the queue with the format choices
	OSStatus status;
	status=AudioQueueNewInput(&recordState.mDataFormat,
							  HandleInputBuffer,
							  &recordState,
							  CFRunLoopGetCurrent(),
							  kCFRunLoopCommonModes,
							  0,
							  &recordState.mQueue);
	if (status) {
#ifdef DEBUG 
		printf("Couldn't establish new queue\n");
#endif
		return NO;
	}
	//create the audio file 
	status=AudioFileCreateWithURL(fileURL, 
								  kAudioFileCAFType,
                                  &recordState.mDataFormat,
								  kAudioFileFlags_EraseFile,
								  &recordState.mAudioFile);
	if (status) {
#ifdef DEBUG
		printf("Couldn't establish the audio file\n");
#endif
		return NO;
	}
	//set up the buffers
	DeriveBufferSize(recordState.mQueue, 
					 recordState.mDataFormat, 
					 0.1, &recordState.bufferByteSize);
#ifdef	DEBUG
	printf("buffer byte size:%ld",recordState.bufferByteSize);
#endif
	for (int i=0; i<kNumberBuffers; i++) {
		status=AudioQueueAllocateBuffer(recordState.mQueue,
										recordState.bufferByteSize,
										&recordState.mBuffers[i]);
		if (status) {
#ifdef	DEBUG
			printf("Couldn't establish the queue buffer\n");
#endif
			return NO;
		}
		status=AudioQueueEnqueueBuffer(recordState.mQueue,
									   recordState.mBuffers[i],
									   0, NULL);
		if (status) {
#ifdef	DEBUG
			printf("Error enqueuing buffer %d\n",i);
#endif
			return NO;
		}
		
    }
	//Enable metering
	UInt32	enableMetering=YES;
	status=AudioQueueSetProperty(recordState.mQueue, 
								 kAudioQueueProperty_EnableLevelMetering,
								 &enableMetering, sizeof(enableMetering));
	if (status) {
#ifdef	DEBUG
		printf("could not enable metering\n");
#endif
		return NO;
	}
	
	//start the recording
	status=AudioQueueStart(recordState.mQueue,
						   NULL);
	if (status) {
#ifdef	DEBUG
		printf("Could not start Audio Queue.");
#endif
		return NO;
	}
	
	recordState.mCurrentPacket=0;
	recordState.mIsRunning=TRUE;
#ifdef DEBUG
	printf("audio queue record start....\n");
#endif
	return YES;
	
}
#else
- (BOOL)start:(id<RecordFilterDelegate>)delegate{
    
	recordState.filterDelegate=delegate;
	//Set up the audio format
	[self setUpAudioDataFormat:&recordState.mDataFormat];
	
	recordState.mCurrentPacket=0;
	
	//initialize the queue with the format choices
	OSStatus status;
	status=AudioQueueNewInput(&recordState.mDataFormat,
							  HandleInputBuffer,
							  &recordState,
							  CFRunLoopGetCurrent(),
							  kCFRunLoopCommonModes,
							  0,
							  &recordState.mQueue);
	if (status) {
#ifdef DEBUG 
		printf("Couldn't establish new queue\n");
#endif
		return NO;
	}
	//set up the buffers
	DeriveBufferSize(recordState.mQueue, 
					 recordState.mDataFormat, 
					 0.1, &recordState.bufferByteSize);
#ifdef	DEBUG
	printf("buffer byte size:%ld",recordState.bufferByteSize);
#endif
	for (int i=0; i<kNumberBuffers; i++) {
		status=AudioQueueAllocateBuffer(recordState.mQueue,
										recordState.bufferByteSize,
										&recordState.mBuffers[i]);
		if (status) {
#ifdef	DEBUG
			printf("Couldn't establish the queue buffer\n");
#endif
			return NO;
		}
		status=AudioQueueEnqueueBuffer(recordState.mQueue,
									   recordState.mBuffers[i],
									   0, NULL);
		if (status) {
#ifdef	DEBUG
			printf("Error enqueuing buffer %d\n",i);
#endif
			return NO;
		}
		
	}
	//Enable metering
	UInt32	enableMetering=YES;
	status=AudioQueueSetProperty(recordState.mQueue, 
								 kAudioQueueProperty_EnableLevelMetering,
								 &enableMetering, sizeof(enableMetering));
	if (status) {
#ifdef	DEBUG
		printf("could not enable metering\n");
#endif
		return NO;
	}
	
	//start the recording
	status=AudioQueueStart(recordState.mQueue,
						   NULL);
	if (status) {
#ifdef	DEBUG
		printf("Could not start Audio Queue.");
#endif
		return NO;
	}
	
	recordState.mCurrentPacket=0;
	recordState.mIsRunning=TRUE;
#ifdef DEBUG
	printf("audio queue record start....\n");
#endif
	return YES;
	
}
/*- (BOOL)start:(NSString *)filePath filterCallback:(InputBufferHandler) inHandler{
 recordState.inputBufferHandler=inHandler;
 //Set up the audio format and the url to record
 [self setUpAudioDataFormat:&recordState.mDataFormat];
 
 CFURLRef fileURL=CFURLCreateFromFileSystemRepresentation(
 NULL, (const UInt8 *)[filePath UTF8String],
 [filePath length], NO);
 recordState.mCurrentPacket=0;
 
 //initialize the queue with the format choices
 OSStatus status;
 status=AudioQueueNewInput(&recordState.mDataFormat,
 HandleInputBuffer,
 &recordState,
 CFRunLoopGetCurrent(),
 kCFRunLoopCommonModes,
 0,
 &recordState.mQueue);
 if (status) {
 #ifdef DEBUG 
 printf("Couldn't establish new queue\n");
 #endif
 return NO;
 }
 //create the audio file 
 status=AudioFileCreateWithURL(fileURL, 
 kAudioFileCAFType,
 &recordState.mDataFormat,
 kAudioFileFlags_EraseFile,
 &recordState.mAudioFile);
 if (status) {
 #ifdef DEBUG
 printf("Couldn't establish the audio file\n");
 #endif
 return NO;
 }
 //set up the buffers
 DeriveBufferSize(recordState.mQueue, 
 recordState.mDataFormat, 
 0.1, &recordState.bufferByteSize);
 #ifdef	DEBUG
 printf("buffer byte size:%ld",recordState.bufferByteSize);
 #endif
 for (int i=0; i<kNumberBuffers; i++) {
 status=AudioQueueAllocateBuffer(recordState.mQueue,
 recordState.bufferByteSize,
 &recordState.mBuffers[i]);
 if (status) {
 #ifdef	DEBUG
 printf("Couldn't establish the queue buffer\n");
 #endif
 return NO;
 }
 status=AudioQueueEnqueueBuffer(recordState.mQueue,
 recordState.mBuffers[i],
 0, NULL);
 if (status) {
 #ifdef	DEBUG
 printf("Error enqueuing buffer %d\n",i);
 #endif
 return NO;
 }
 
 }
 //Enable metering
 UInt32	enableMetering=YES;
 status=AudioQueueSetProperty(recordState.mQueue, 
 kAudioQueueProperty_EnableLevelMetering,
 &enableMetering, sizeof(enableMetering));
 if (status) {
 #ifdef	DEBUG
 printf("could not enable metering\n");
 #endif
 return NO;
 }
 
 //start the recording
 status=AudioQueueStart(recordState.mQueue,
 NULL);
 if (status) {
 #ifdef	DEBUG
 printf("Could not start Audio Queue.");
 #endif
 return NO;
 }
 
 recordState.mCurrentPacket=0;
 recordState.mIsRunning=TRUE;
 #ifdef DEBUG
 printf("audio queue record start....\n");
 #endif
 return YES;
 
 }
 #else
 - (BOOL)start:(InputBufferHandler) inHandler{
 
 recordState.inputBufferHandler=inHandler;
 //Set up the audio format
 [self setUpAudioDataFormat:&recordState.mDataFormat];
 
 recordState.mCurrentPacket=0;
 
 //initialize the queue with the format choices
 OSStatus status;
 status=AudioQueueNewInput(&recordState.mDataFormat,
 HandleInputBuffer,
 &recordState,
 CFRunLoopGetCurrent(),
 kCFRunLoopCommonModes,
 0,
 &recordState.mQueue);
 if (status) {
 #ifdef DEBUG 
 printf("Couldn't establish new queue\n");
 #endif
 return NO;
 }
 //set up the buffers
 DeriveBufferSize(recordState.mQueue, 
 recordState.mDataFormat, 
 0.1, &recordState.bufferByteSize);
 #ifdef	DEBUG
 printf("buffer byte size:%ld",recordState.bufferByteSize);
 #endif
 for (int i=0; i<kNumberBuffers; i++) {
 status=AudioQueueAllocateBuffer(recordState.mQueue,
 recordState.bufferByteSize,
 &recordState.mBuffers[i]);
 if (status) {
 #ifdef	DEBUG
 printf("Couldn't establish the queue buffer\n");
 #endif
 return NO;
 }
 status=AudioQueueEnqueueBuffer(recordState.mQueue,
 recordState.mBuffers[i],
 0, NULL);
 if (status) {
 #ifdef	DEBUG
 printf("Error enqueuing buffer %d\n",i);
 #endif
 return NO;
 }
 
 }
 //Enable metering
 UInt32	enableMetering=YES;
 status=AudioQueueSetProperty(recordState.mQueue, 
 kAudioQueueProperty_EnableLevelMetering,
 &enableMetering, sizeof(enableMetering));
 if (status) {
 #ifdef	DEBUG
 printf("could not enable metering\n");
 #endif
 return NO;
 }
 
 //start the recording
 status=AudioQueueStart(recordState.mQueue,
 NULL);
 if (status) {
 #ifdef	DEBUG
 printf("Could not start Audio Queue.");
 #endif
 return NO;
 }
 
 recordState.mCurrentPacket=0;
 recordState.mIsRunning=TRUE;
 #ifdef DEBUG
 printf("audio queue record start....\n");
 #endif
 return YES;
 
 }*/

#endif
- (void)reallyStop{
#ifdef	DEBUG
	printf("audio queue record stop....\n");
#endif
	AudioQueueFlush(recordState.mQueue);
	AudioQueueStop(recordState.mQueue, NO);
	recordState.mIsRunning=NO;
	for (int i=0; i<kNumberBuffers; i++) {
		AudioQueueFreeBuffer(recordState.mQueue, recordState.mBuffers[i]);
	}
	AudioQueueDispose(recordState.mQueue, YES);
#ifdef writeToFile
	AudioFileClose(recordState.mAudioFile);
#endif
}
- (void)stop{
	[self performSelector:@selector(reallyStop) withObject:nil afterDelay:0.5];
}
- (void)reallyPause{
#ifdef	DEBUG
	printf("audio queue record pause.....\n");
#endif
	if (!recordState.mQueue) {
		NSLog(@"Nothing to pause\n.");
		return;
	}
	OSStatus status=AudioQueuePause(recordState.mQueue);
	if (status) {
#ifdef DEBUG
		NSLog(@"Error pausing audio queue\n.");
#endif
	}
}

- (void)pause{
	[self performSelector:@selector(reallyPause) withObject:nil afterDelay:0.2];
}
- (float)currentTime{
	AudioTimeStamp outTimeStamp;
	OSStatus status=AudioQueueGetCurrentTime(recordState.mQueue, NULL, &outTimeStamp, NULL);
	if (status) {
#ifdef	DEBUG
		NSLog(@"ERROR:Could not retrieve current time\n");
#endif
		return 0.0f;
	}
	return outTimeStamp.mSampleTime;
}
- (BOOL)resume{
#ifdef	DEBUG
	printf("audio queue record resume....\n");
#endif
	if (!recordState.mQueue) {
#ifdef	DEBUG
		NSLog(@"Nothing to resume");
#endif
		return NO;
	}
	OSStatus status=AudioQueueStart(recordState.mQueue, NULL);
	if (status) {
#ifdef	DEBUG
		NSLog(@"Error resuming audio queue");
#endif
		return NO;
	}
	return YES;
}
- (BOOL)isRecording{
	return recordState.mIsRunning;
}
@end
