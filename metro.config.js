const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

config.resolver.resolveRequest = require('metro-resolver-symlinks').create  ({ // or `createReactNativeResolver`
  get  (context, moduleName, platform) {
    if (moduleName.startsWith('@/')) {
      return context.resolveRequest(context, moduleName.replace(/^@\//, './'), platform);
    }
    return context.resolveRequest(context, moduleName, platform);
  },
});

module.exports = config;