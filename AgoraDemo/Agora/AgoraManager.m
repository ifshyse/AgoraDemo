//
//  AgoraManager.m
//  AgoraDemo
//
//  Created by TOOS on 18/4/3.
//  Copyright © 2018年 TOOS. All rights reserved.
//

#import "AgoraManager.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <AgoraRtcEngineKit/AgoraMediaIO.h>

@import AVFoundation;

@interface AgoraManager ()
<
AgoraRtcEngineDelegate
>
{
    BOOL hasJoinedChannel;
    BOOL hasAudioMuted;
    BOOL enabledSpeaker;
    BOOL hasStartEchoTest;
    
    NSUInteger  curUserId;
    NSString    *curChannelName;
}

@property (strong ,nonatomic) AgoraRtcEngineKit<AgoraVideoSinkProtocol>  *agoraAudio;
//@property (assign ,readwrite) AgoraRtcQuality  curNetworkQuality;
//@property (assign ,readwrite) AgoraRtcQuality  curVoiceAudioMediaQuality;

@end

@implementation AgoraManager


- (instancetype)initWithVendorKey:(NSString*)vendorKey
{
    self = [super init];
    if (self) {
        
        _agoraAudio = [AgoraRtcEngineKit sharedEngineWithAppId:vendorKey delegate:self];
        
        //NSParameterAssert(_agoraAudio);
        
        //_curNetworkQuality = AgoraRtc_Quality_Unknown;
        //_curVoiceAudioMediaQuality = AgoraRtc_Quality_Unknown;
        
        [self enableNetworkTest];
        
        //[_agoraAudio enableVendorMessage];
        
        /**
         BOOL foundHeadset = NO;
         NSArray *availableInputs = [[AVAudioSession sharedInstance] availableInputs];
         for (AVAudioSessionPortDescription *portDescription in availableInputs) {
         if ([portDescription.portType isEqualToString:@"Headphones"]) {
         foundHeadset = YES;
         break;
         }
         }
         if (foundHeadset) { // hasMicphone
         // false: Switches to headset
         [self setEnableSpeakerphone:NO];
         }
         else {
         [self setEnableSpeakerphone:YES];
         }
         
         // 添加通知，拔出耳机后切换到speaker
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
         **/
#ifdef DEBUG
        NSString *version = [AgoraRtcEngineKit getSdkVersion];
        NSLog(@"Agora Version = %@", version);
        
#endif
    }
    return self;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [self leaveChannel];
    _agoraAudio = nil;
}


#pragma mark - NSNotification

/**
 *  一旦输出改变则执行此方法
 *
 *  @param notification 输出改变通知对象
 */
- (void)onRouteChange:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription = dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription = [routeDescription.outputs firstObject];
        // 原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            // true: Switches to speakerphone
            [self setEnableSpeakerphone:YES];
        }
    }
    else if (changeReason == AVAudioSessionRouteChangeReasonNewDeviceAvailable)  {
        AVAudioSessionRouteDescription *routeDescription = dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription = [routeDescription.outputs firstObject];
        if ([portDescription.portType isEqualToString:@"Speaker"]) {
            // false: Switches to headset
            [self setEnableSpeakerphone:NO];
        }
    }
}

#pragma mark - public

#if (!TARGET_IPHONE_SIMULATOR && sAGORA_USE_VIDEO == 1)
// enable Video
- (int)enableVideo
{
    return [self.agoraAudio enableVideo];
}

// disable video
- (int)disableVideo
{
    return [self.agoraAudio disableVideo];
}
#endif
// Specify sdk profile
- (int)setProfile:(NSString *)profilePath merge:(BOOL)merge
{
    /**
     NSString *logTextPath = [profilePath stringByAppendingPathComponent:@"com.agora.CacheLogs/agorasdk.log"];
     NSDictionary *profileDic = @{@"mediaSdk": @{@"logFile": logTextPath}};
     NSData *profileData = [NSJSONSerialization dataWithJSONObject:profileDic options:0 error:NULL];
     NSString *profileString = [[NSString alloc] initWithData:profileData encoding:NSUTF8StringEncoding];
     
     return [self.agoraAudio setProfile:profileString merge:merge];
     **/
    return 0;
}

// Create an open UDP socket to the AgoraAudioKit cloud service to join a channel.
- (int)joinChannelByKey:(NSString *)vendorKey channelName:(NSString *)channelName info:(NSString *)info uid:(NSUInteger)uid
{
    int result = -1;
    if (channelName.length <= 0) {
        return result;
    }
    
    if (hasJoinedChannel) {
        return 0;
    }
    
    curUserId = uid;
    curChannelName = channelName;
    
    
    __weak __typeof(self) weakSelf = self;
    result = [self.agoraAudio joinChannelByToken:vendorKey channelId:channelName info:info uid:uid joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        [weakSelf handleJoinChannelSuccess:channel uid:uid elapsed:elapsed];
    }];
    
    return result;
}

// Leave channel positively.
- (int)leaveChannel
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    [self disableNetworkTest];
    
//    self.qualityBlock = nil;
//    self.errorBlock = nil;
//    self.leaveChannelBlock = nil;
//    self.updateSessionBlock = nil;
//    self.networkQualityBlock = nil;
//    self.voiceMuteBlock = nil;
//    self.videoMuteBlock = nil;
//    self.joinChannelSuccess = nil;
//    self.didJoinedBlock = nil;
//    self.echoTestBlock = nil;
//    self.didOfflineBlock = nil;
//    self.localVideoStatusBlock = nil;
    
    if ([_agoraAudio respondsToSelector:@selector(setAgoraRtcEngineDelegate:)]) {
        [_agoraAudio performSelector:@selector(setAgoraRtcEngineDelegate:) withObject:nil];
    }
    if ([_agoraAudio respondsToSelector:@selector(setJoinSuccessBlock:)]) {
        [_agoraAudio performSelector:@selector(setJoinSuccessBlock:) withObject:nil];
    }
    
    result = [self.agoraAudio leaveChannel:nil];
    
    _agoraAudio = nil;
    
    // remove the callback to fixed ___ZN5agora3rtc28RtcEngineEventHandlerIosImpl14onLeaveChannelERKNS0_8RtcStatsE_block_invoke172 + 44 issue
    /*
     __weak __typeof(self) weakSelf = self;
     result = [self.agoraAudio leaveChannel:^(AgoraRtcStats* stat) {
     [weakSelf handleLeaveChannelWith:stat];
     #ifdef DEBUG
     NSLog(@"leaveChannel->stat = %@", stat);
     #endif
     }];*/
    [AgoraRtcEngineKit destroy];
    
    hasJoinedChannel = NO;
    
    return result;
}

- (int)renewToken:(NSString*) token
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio renewToken:token];
    return result;
}

- (int)setInEarMonitoringVolume:(NSInteger)volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setInEarMonitoringVolume:volume];
    return result;
}

- (int)setAudioProfile:(AgoraAudioProfile)profile
              scenario:(AgoraAudioScenario)scenario
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setAudioProfile:profile scenario:scenario];
    return result;
}

- (int)setDefaultAudioRouteToSpeakerphone:(BOOL)defaultToSpeaker
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setDefaultAudioRouteToSpeakerphone:defaultToSpeaker];
    return result;
}

// Start echo test.
- (int)startEchoTest
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    if (hasStartEchoTest) {
        return result;
    }
    result = [self.agoraAudio startEchoTest:^(NSString *channel, NSUInteger uid, NSInteger elapsed) {
        //if (self.echoTestBlock) {
          //  self.echoTestBlock(channel, uid, elapsed);
        //}
    }];
    
    hasStartEchoTest = YES;
    
    return result;
}

// Stop echo test
- (int)stopEchoTest
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    if (!hasStartEchoTest) {
        return result;
    }
    result = [self.agoraAudio stopEchoTest];
    hasStartEchoTest = NO;
    
    return result;
}

- (int)enableLastmileTest
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio enableLastmileTest];
    return result;
}

- (int)disableLastmileTest
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio disableLastmileTest];
    return result;
}



// Enable network test
- (int)enableNetworkTest
{
    int result = 0;
    
    //result = [self.agoraAudio enableNetworkTest];
    
#ifdef DEBUG
    NSParameterAssert(result == 0);
#endif
    return result;
    
}

// Disable network test.
- (int)disableNetworkTest
{
    int result = 0;
    //result = [self.agoraAudio disableNetworkTest];
    return result;
}


- (int)muteLocalAudioStream:(BOOL)shouldMute
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    if (hasAudioMuted == shouldMute) {
        return result;
    }
    result = [self.agoraAudio muteLocalAudioStream:shouldMute];
    
    if (result == 0) {
        hasAudioMuted = shouldMute;
    }
    
    return result;
}

- (void)setMute:(BOOL)mute
{
    [self muteLocalAudioStream:mute];
}

- (BOOL)isMuted
{
    return hasAudioMuted;
}


- (int)muteAllRemoteAudioStreams:(BOOL)muted
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio muteLocalAudioStream:muted];
    return result;
}

- (int)muteRemoteAudioStream:(NSUInteger)uid mute:(BOOL)mute
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio muteRemoteAudioStream:uid mute:mute];
    return result;
}

- (int)getAudioMixingDuration
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio getAudioMixingDuration];
    return result;
}

- (int)getAudioMixingCurrentPosition
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio getAudioMixingCurrentPosition];
    return result;
}

- (int)setAudioMixingPosition:(NSInteger) pos
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setAudioMixingPosition:pos];
    return result;
}

- (int)adjustAudioMixingVolume:(NSInteger) volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio adjustAudioMixingVolume:volume];
    return result;
}

- (int)setEnableSpeakerphone:(BOOL)enableSpeaker
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    if ([self.agoraAudio isSpeakerphoneEnabled] == enableSpeaker) {
        return result;
    }
    
    result = [self.agoraAudio setEnableSpeakerphone:enableSpeaker];
    enabledSpeaker = enableSpeaker;
    return result;
}

- (BOOL)isSpeakerphoneEnabled
{
    return [self.agoraAudio isSpeakerphoneEnabled];
}

// Set speaker volume
// volume set between 0 and 255
- (int)setSpeakerphoneVolume:(NSUInteger)volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio setSpeakerphoneVolume:volume];
    return result;
}

// Set parameter for the Agora Audio Engine.
// options, sdk options in json format.
- (int)setParameters:(NSString *)options
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio setParameters:options];
    return result;
}

- (int)enableAudio
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio enableAudio];
    return result;
}

- (int)disableAudio
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio disableAudio];
    return result;
}

// volume report
// interval, <=0 - disabled, >0 interval in ms
- (int)enableAudioVolumeIndication:(NSInteger)interval smooth:(NSInteger)smooth
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio enableAudioVolumeIndication:interval smooth:smooth];
    return result;
}

- (void)enableExternalAudioSourceWithSampleRate:(NSUInteger)sampleRate
                               channelsPerFrame:(NSUInteger)channelsPerFrame
{
    if (!hasJoinedChannel) {
        return;
    }
    [self.agoraAudio enableExternalAudioSourceWithSampleRate:sampleRate channelsPerFrame:channelsPerFrame];
}

- (void)disableExternalAudioSource
{
    if (!hasJoinedChannel) {
        return;
    }
    [self.agoraAudio disableExternalAudioSource];
}

- (double) getEffectsVolume
{
    if (!hasJoinedChannel) {
        return 0;
    }
    return [self.agoraAudio getEffectsVolume];
}

- (int) setEffectsVolume:(double) volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setEffectsVolume: volume];
    return result;
}

- (int) setVolumeOfEffect:(int) soundId
               withVolume:(double) volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setVolumeOfEffect: soundId withVolume:volume];
    return result;
}

- (int) setLocalVoicePitch:(double) pitch
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setLocalVoicePitch:pitch];
    return result;
}

- (int)setLocalVoiceEqualizationOfBandFrequency:(AgoraAudioEqualizationBandFrequency)bandFrequency withGain:(NSInteger)gain
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setLocalVoiceEqualizationOfBandFrequency:bandFrequency withGain:gain];
    return result;
}

- (int)setLocalVoiceReverbOfType:(AgoraAudioReverbType)reverbType withValue:(NSInteger)value
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio setLocalVoiceReverbOfType:reverbType withValue:value];
    return result;
}

- (int) playEffect: (int) soundId
          filePath: (NSString*) filePath
              loop: (BOOL) loop
             pitch: (double) pitch
               pan: (double) pan
              gain: (double) gain
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio playEffect:soundId filePath:filePath loop:loop pitch:pitch pan:pan gain:gain];
    return result;
}

- (int) stopEffect:(int) soundId
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio stopEffect:soundId];
    return result;
}

- (int) stopAllEffects
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio stopAllEffects];
    return result;
}

- (int) preloadEffect:(int) soundId
             filePath:(NSString*) filePath
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio preloadEffect:soundId filePath:filePath];
    return result;
}

- (int) unloadEffect:(int) soundId
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio unloadEffect:soundId];
    return result;
}

- (int) pauseEffect:(int) soundId
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio pauseEffect:soundId];
    return result;
}

- (int)pauseAllEffects
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio pauseAllEffects];
    return result;
}

- (int) resumeEffect:(int) soundId
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio resumeEffect:soundId];
    return result;
}

- (int) resumeAllEffects
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    result = [self.agoraAudio resumeAllEffects];
    return result;
}

- (void)setVideoSource:(id<AgoraVideoSourceProtocol>_Nullable)videoSource
{
    if (!hasJoinedChannel) {
        [self.agoraAudio setVideoSource:videoSource];
    }
}

- (id<AgoraVideoSourceProtocol> _Nullable)videoSource
{
    if (hasJoinedChannel) {
        return  nil;
    }
    return [self.agoraAudio videoSource];
}

- (void)setLocalVideoRenderer:(id<AgoraVideoSinkProtocol> _Nullable)videoRenderer
{
    if (!hasJoinedChannel) {
        return;
    }
    [self.agoraAudio setLocalVideoRenderer:videoRenderer];
}

- (int)enableAudioQualityIndication:(BOOL)enabled
{
    /**
     int result = 0;
     if (!hasJoinedChannel) {
     return result;
     }
     
     result = [self.agoraAudio enableAudioQualityIndication:enabled];
     return result;
     **/
    return 0;
}

// 启用接收端传输质量提示
- (int)enableTransportQualityIndication:(BOOL)enabled
{
    /**
     int result = 0;
     if (!hasJoinedChannel) {
     return result;
     }
     
     result = [self.agoraAudio enableTransportQualityIndication:enabled];
     return result;
     **/
    return 0;
}


// 设置日志文件
- (int)setLogFile:(NSString*)filePath
{
    return [self.agoraAudio setLogFile:filePath];
}

// Enable recap stat
// @param interval, <=0 - disabled, >0 interval in ms.
- (int)enableRecapStat:(NSInteger)interval
{
    /**
     int result = 0;
     if (!hasJoinedChannel) {
     return result;
     }
     
     result = [self.agoraAudio enableRecap:interval];
     return result;
     **/
    return 0;
}

// Start playing recap conversation
- (int)startRecapPlay
{
    /**
     int result = 0;
     if (!hasJoinedChannel) {
     return result;
     }
     
     result = [self.agoraAudio playRecap];
     return result;
     **/
    return 0;
}

// Start recording conversation to file specified by the file path
- (int)startAudioRecording:(NSString*)filePath
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    //result = [self.agoraAudio startAudioRecording:filePath];
    return result;
    
}

// Stop conversation recording
- (int)stopAudioRecording
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio stopAudioRecording];
    return result;
}

- (int)adjustRecordingSignalVolume:(NSInteger)volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio adjustRecordingSignalVolume:volume];
    return result;
}

- (int)adjustPlaybackSignalVolume:(NSInteger)volume
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio adjustPlaybackSignalVolume:volume];
    return result;
}

- (int)setEncryptionSecret:(NSString*)secret
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio setEncryptionSecret:secret];
    return result;
}

- (int)setEncryptionMode:(NSString*)encryptionMode
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio setEncryptionMode:encryptionMode];
    return result;
}

- (int)createDataStream:(NSInteger*)streamId reliable:(BOOL)reliable ordered:(BOOL)ordered
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio createDataStream:streamId reliable:reliable ordered:ordered];
    return result;
}

- (int)sendStreamMessage:(NSInteger)streamId data:(NSData*)data
{
    int result = 0;
    if (!hasJoinedChannel) {
        return result;
    }
    
    result = [self.agoraAudio sendStreamMessage:streamId data:data];
    return result;
}

- (NSString*)makeQualityReportUrl:(NSString*)vendorKey
                          channel:(NSString*)channel
                      listenerUid:(NSUInteger)listenerUid
                      speakerrUid:(NSUInteger)speakerUid
{
    if (!hasJoinedChannel) {
        return nil;
    }
    NSString* result = @"";
    
    //NSString *result = [self.agoraAudio makeQualityReportUrl:channel listenerUid:listenerUid speakerrUid:speakerUid reportFormat:AgoraRtc_QualityReportFormat_Html];
    return result;
}

- (NSString*)getCallId
{
    if (!hasJoinedChannel) {
        return nil;
    }
    
    NSString *result = [self.agoraAudio getCallId];
    return result;
}

- (int)rate:(NSString*)callId rating:(NSInteger)rating description:(NSString*)description
{
    if (!hasJoinedChannel) {
        return NO;
    }
    
    int result = [self.agoraAudio rate:callId rating:rating description:description];
    return result;
}

- (int)complain:(NSString*)callId description:(NSString*)description
{
    if (!hasJoinedChannel) {
        return NO;
    }
    
    int result = [self.agoraAudio complain:callId description:description];
    return result;
}

- (int)sendVendorMessage:(NSData*)data
{
    if (self.agoraAudio && data.length > 0) {
        //return [self.agoraAudio sendVendorMessage:data];
    }
    return 0;
}

#pragma mark - video
#if (!TARGET_IPHONE_SIMULATOR && AGORA_USE_VIDEO == 1)
// 设置本地视频
- (int)setupLocalVideo:(AgoraRtcVideoCanvas*)local
{
    return [self.agoraAudio setupLocalVideo:local];
}

// 设置远端视频显示视图
- (int)setupRemoteVideo:(AgoraRtcVideoCanvas*)remote
{
    return [self.agoraAudio setupRemoteVideo:remote];
}

// 设置本地视频显示模式 setLocalRenderMode
- (int)setLocalRenderMode:(VoiceRtcRenderMode)mode
{
    return [self.agoraAudio setLocalRenderMode:(AgoraRtcRenderMode)mode];
}

// 设置远端视频显示模式 setRemoteRenderMode
- (int)setRemoteRenderMode:(NSUInteger)uid mode:(VoiceRtcRenderMode)mode
{
    return [self.agoraAudio setRemoteRenderMode:uid mode:(AgoraRtcRenderMode)mode];
}

// 切换视频流的显示视窗
- (int)switchView:(NSUInteger)uid1 andAnother:(NSUInteger)uid2
{
    return [self.agoraAudio switchView:uid1 andAnother:uid2];
}

// 设置视频最大码率
- (int)setVideoMaxBitrate:(int)bitrate
{
    return [self.agoraAudio setVideoMaxBitrate:bitrate];
}

// 设置视频最大帧率
- (int)setVideoMaxFrameRate:(int)frameRate
{
    return [self.agoraAudio setVideoMaxFrameRate:frameRate];
}

// 暂停本地视频流
- (int)muteLocalVideoStream:(BOOL)muted
{
    return [self.agoraAudio muteLocalVideoStream:muted];
}

// 暂停所有远端视频流
- (int)muteAllRemoteVideoStreams:(BOOL)muted
{
    return [self.agoraAudio muteAllRemoteVideoStreams:muted];
}

- (int)setVideoResolution:(int)width andHeight:(int)height
{
    if (!hasJoinedChannel) {
        return NO;
    }
    
    int result = [self.agoraAudio setVideoResolution:width andHeight:height];
    return result;
    
}

- (int)switchCamera
{
    if (!hasJoinedChannel) {
        return NO;
    }
    
    int result = [self.agoraAudio switchCamera];
    return result;
}

#endif

#pragma mark - private

//- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraRtcErrorCode)warningCode
//{
//    
//}
//- (void)handleQualityWith:(NSUInteger)uid quality:(AgoraRtcQuality)quality delay:(NSUInteger)delay jitter:(NSUInteger)jitter lost:(NSUInteger)lost lost2:(NSUInteger)lost2
//{
    //if (self.curVoiceAudioMediaQuality != quality) {
        //self.curVoiceAudioMediaQuality = quality;
        // MOD BY MICHAEL
        
        //if (self.qualityBlock) {
        //    self.qualityBlock(uid, (VoiceAudioMediaQuality)quality, delay, jitter, lost, lost2);
        //}
        /**
         // audio quality only for other user
         if (self.networkQualityBlock) {
         self.networkQualityBlock((VoiceAudioMediaQuality)quality);
         }**/
    //}
//}

//- (void)handleErrorWith:(AgoraRtcErrorCode)errorCode
//{
    //if (self.errorBlock) {
      //  self.errorBlock((VoiceAudioErrorCode)errorCode);
    //}
//}

//- (void)handleLeaveChannelWith:(AgoraRtcStats *)stat
//{
//    //    _agoraAudio = nil;
//    if (self.leaveChannelBlock) {
//        // duration : 通话时长
//        // txBytes : 发送字节数
//        // rxBytes : 接收字节数
//        self.leaveChannelBlock(stat.duration, stat.txBytes, stat.rxBytes);
//    }
//}

//- (void)handleUpdateSessionStatWith:(AgoraRtcStats *)stat
//{
//    if (self.updateSessionBlock) {
//        self.updateSessionBlock(stat.duration, stat.txBytes, stat.rxBytes);
//    }
//}

//- (void)handleNetworkQualityWith:(AgoraRtcQuality)quality
//{
//    if (self.curNetworkQuality != quality) {
//        self.curNetworkQuality = quality;
//        if (self.networkQualityBlock) {
//            self.networkQualityBlock((VoiceAudioMediaQuality)quality);
//        }
//    }
//}

- (void)handleUserJoinedWith:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
//    if (self.didJoinedBlock) {
//        self.didJoinedBlock(curChannelName, uid, elapsed);
//    }
}

- (void)handleUserOfflineWith:(NSUInteger)uid
{
//    if (self.didOfflineBlock) {
//        self.didOfflineBlock(uid);
//    }
}

- (void)handleUserMuteAudioWith:(NSUInteger)uid muted:(BOOL)muted
{
    if (uid == curUserId) {
        hasAudioMuted = muted;
    }
    
//    if (self.voiceMuteBlock) {
//        self.voiceMuteBlock(uid, muted);
//    }
}

- (void)handleUserMuteVideoWith:(NSUInteger)uid muted:(BOOL)muted
{
//    if (self.videoMuteBlock) {
//        self.videoMuteBlock(uid, muted);
//    }
}

- (void)handleJoinChannelSuccess:(NSString*)channel uid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    hasJoinedChannel = YES;
    
//    if (self.joinChannelSuccess) {
//        self.joinChannelSuccess(channel, uid, elapsed);
//    }
}

- (void)handleLocalVideoStat:(NSInteger)sentBytes frames:(NSInteger)sentFrames
{
//    if (self.localVideoStatusBlock) {
//        self.localVideoStatusBlock(sentBytes, sentFrames);
//    }
}

- (void)handleAudioTransportQuality:(NSInteger)uid delay:(NSInteger)delay lost:(NSInteger)lost
{
    
}

- (void)handleVideoTransportQuality:(NSInteger)uid delay:(NSInteger)delay lost:(NSInteger)lost
{
    
}

- (void)handleVendorMessageFromUid:(NSInteger)uid data:(NSData*)data
{
//    if (self.vendorMessageBlock) {
//        self.vendorMessageBlock(uid, data);
//    }
}


#pragma mark - AgoraRtcEngineDelegate

//- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraRtcWarningCode)warningCode
//{
//    
//}
//- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode
//{
//    [self handleErrorWith:errorCode];
//}
- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray*)speakers totalVolume:(NSInteger)totalVolume
{
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    [self handleUserJoinedWith:uid elapsed:elapsed];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid
{
    [self handleUserOfflineWith:uid];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    [self handleUserMuteAudioWith:uid muted:muted];
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine
{
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed
{
    [self handleJoinChannelSuccess:channel uid:uid elapsed:elapsed];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRejoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed
{
    
}

//- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportRtcStats:(AgoraRtcStats*)stats
//{
//    
//}

// 离开频道回调
//- (void)rtcEngine:(AgoraRtcEngineKit *)engine didLeaveChannelWithStats:(AgoraRtcStats*)stats
//{
//    [self handleLeaveChannelWith:stats];
//}
//
//- (void)rtcEngine:(AgoraRtcEngineKit *)engine audioQualityOfUid:(NSUInteger)uid quality:(AgoraRtcQuality)quality delay:(NSUInteger)delay lost:(NSUInteger)lost
//{
//    [self handleQualityWith:uid quality:quality delay:delay jitter:0 lost:lost lost2:0];
//}
//
//- (void)rtcEngine:(AgoraRtcEngineKit *)engine networkQuality:(AgoraRtcQuality)quality
//{
//    [self handleNetworkQualityWith:quality];
//}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine receiveVendorMessageFromUid:(NSUInteger)uid data:(NSData*)data
{
    [self handleVendorMessageFromUid:uid data:data];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didApiCallExecute:(NSString*)api error:(NSInteger)error
{
    
}

#pragma mark - AgoraVideoSink Protocol
- (BOOL)shouldInitialize
{
    return NO;
}

- (void)shouldStart
{
    
}

- (void)shouldStop
{
    
}

- (void)shouldDispose
{
    
}

- (AgoraVideoBufferType)bufferType
{
    return 1;
}

- (AgoraVideoPixelFormat)pixelFormat
{
    return 0;
}

- (void)renderPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer
                 rotation:(AgoraVideoRotation)rotation
{
    
}

- (void)renderRawData:(void * _Nonnull)rawData
                 size:(CGSize)size
             rotation:(AgoraVideoRotation)rotation
{
    
}

@end
