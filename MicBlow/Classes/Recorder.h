//
//  Recorder.h
//  AudioRecordTest
//
//  Created by perun on 11-9-1.
//  Copyright 2011 __cn.perun__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>

//#define writeToFile	1
#define kNumberBuffers	3 //set the number of audio queue buffers to use

@protocol RecordFilterDelegate <NSObject>

- (void)filterRecordData:(short int *)inData length:(UInt32)length;

@end

typedef void (*InputBufferHandler)(
								   short int * inData,
								   UInt32 length);
typedef struct  {
	AudioStreamBasicDescription mDataFormat;
	AudioQueueRef mQueue;
	AudioQueueBufferRef mBuffers[kNumberBuffers];
#ifdef writeToFile
	AudioFileID	mAudioFile;
#endif
	//InputBufferHandler  inputBufferHandler;
    id<RecordFilterDelegate> filterDelegate;
	UInt32	bufferByteSize;
	SInt64	mCurrentPacket;
	BOOL	mIsRunning;
}RecorderState;

@interface Recorder : NSObject {
	RecorderState recordState;
    
}
#ifdef writeToFile
//- (BOOL)start:(NSString *)filePath filterCallback:(InputBufferHandler) inHandler;
- (BOOL)start:(NSString *)filePath filterDelegate:(id<RecordFilterDelegate>)delegate;
#else
//- (BOOL)start:(InputBufferHandler) inHandler;
- (BOOL)start:(id<RecordFilterDelegate>)delegate;
#endif
- (void)stop;
- (void)pause;
- (BOOL)resume;

@end
