const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const config = getDefaultConfig(__dirname);

config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (moduleName.startsWith('@/')) {
    return context.resolveRequest(context, path.join(context.projectRoot, moduleName.replace('@/', '')), platform);
  }
  return context.resolveRequest(context, moduleName, platform);
};

module.exports = config;