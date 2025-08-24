// How far down is the stacktrace LoggerStackTrace produced from the method Logger.log(...) this package?
const kStackDepthOfThis = 2;
// How many wrapping calls are there between client call to library and the Logger.log(...) method?
// LoggerExposure will here add + 1 to whatever the client already adds. Usually zero, but could be that there are
// additional filters in the client app that have to be bypassed
const kStackDepthOffset = 1;
const kDefaultDateFormat = 'yyyy-MM-dd HH:mm:ss.SSS';
const kOpen = '[';
const kClose = ']';
