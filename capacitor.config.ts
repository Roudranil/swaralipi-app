import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.swaralipi.app',
  appName: 'Swaralipi',
  webDir: 'dist',
  android: {
    androidScheme: 'https',
  },
};

export default config;
