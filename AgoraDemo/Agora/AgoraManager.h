//
//  AgoraManager.h
//  AgoraDemo
//
//  Created by TOOS on 18/4/3.
//  Copyright © 2018年 TOOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AgoraManager : NSObject

- (instancetype)initWithVendorKey:(NSString*)vendorKey;

// Specify sdk profile
- (int)setProfile:(NSString *)profilePath merge:(BOOL)merge;

// Create an open UDP socket to the AgoraAudioKit cloud service to join a channel.
- (int)joinChannelByKey:(NSString *)vendorKey channelName:(NSString *)channelName info:(NSString *)info uid:(NSUInteger)uid;

// Leave channel positively.
- (int)leaveChannel;

// Start echo test.
- (int)startEchoTest;

// Stop echo test
- (int)stopEchoTest;

// Enable network test
- (int)enableNetworkTest;

// Disable network test.
- (int)disableNetworkTest;

- (int)muteLocalAudioStream:(BOOL)muted;
- (void)setMute:(BOOL)mute;

- (BOOL)isMuted;

- (int)muteAllRemoteAudioStreams:(BOOL)muted;

- (int)muteRemoteAudioStream:(NSUInteger)uid mute:(BOOL)mute;

- (int)setEnableSpeakerphone:(BOOL)enableSpeaker;

- (BOOL)isSpeakerphoneEnabled;

// Set speaker volume
// volume set between 0 and 255
- (int)setSpeakerphoneVolume:(NSUInteger)volume;

// Set parameter for the Agora Audio Engine.
// options, sdk options in json format.
- (int)setParameters:(NSString *)options;

// volume report
// interval, <=0 - disabled, >0 interval in ms
// 平滑系数。默认可以设置为 3
- (int)enableAudioVolumeIndication:(NSInteger)interval smooth:(NSInteger)smooth;

// 启用接收端语音质量提示
- (int)enableAudioQualityIndication:(BOOL)enabled;

// 启用接收端传输质量提示
- (int)enableTransportQualityIndication:(BOOL)enabled;

// Enable recap stat
// @param interval, <=0 - disabled, >0 interval in ms.
- (int)enableRecapStat:(NSInteger)interval;

// Start playing recap conversation
- (int)startRecapPlay;

// Start recording conversation to file specified by the file path
- (int)startAudioRecording:(NSString*)filePath;

// Stop conversation recording
- (int)stopAudioRecording;

- (int)sendVendorMessage:(NSData*)data;

#pragma mark - video
#if (!TARGET_IPHONE_SIMULATOR && AGORA_USE_VIDEO == 1)
// enable Video
- (int)enableVideo;

// disable video
- (int)disableVideo;

// 设置本地视频
- (int)setupLocalVideo:(AgoraRtcVideoCanvas*)local;

// 设置远端视频显示视图
- (int)setupRemoteVideo:(AgoraRtcVideoCanvas*)remote;

// 设置本地视频显示模式 setLocalRenderMode
- (int)setLocalRenderMode:(VoiceRtcRenderMode)mode;

// 设置远端视频显示模式 setRemoteRenderMode
- (int)setRemoteRenderMode:(NSUInteger)uid mode:(VoiceRtcRenderMode)mode;

// 切换视频流的显示视窗
- (int)switchView:(NSUInteger)uid1 andAnother:(NSUInteger)uid2;

// 设置视频最大码率
- (int)setVideoMaxBitrate:(int)bitrate;

// 设置视频最大帧率
- (int)setVideoMaxFrameRate:(int)frameRate;

// 暂停本地视频流
- (int)muteLocalVideoStream:(BOOL)muted;

// 暂停所有远端视频流
- (int)muteAllRemoteVideoStreams:(BOOL)muted;

- (int)setVideoResolution:(int)width andHeight:(int)height;

- (int)switchCamera;

#endif


// 设置日志文件
- (int)setLogFile:(NSString*)filePath;

- (NSString*)makeQualityReportUrl:(NSString*)vendorKey
                          channel:(NSString*)channel
                      listenerUid:(NSUInteger)listenerUid
                      speakerrUid:(NSUInteger)speakerUid;
// 获取当前的通话 ID
- (NSString*)getCallId;

// 给通话评分 rate
// 最低 1 分,最高 10 分。
- (int)rate:(NSString*)callId rating:(NSInteger)rating description:(NSString*)description;

- (int)complain:(NSString*)callId description:(NSString*)description;

@end
