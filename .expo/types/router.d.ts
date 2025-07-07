/* eslint-disable */
import * as Router from 'expo-router';

export * from 'expo-router';

declare module 'expo-router' {
  export namespace ExpoRouter {
    export interface __routes<T extends string = string> extends Record<string, unknown> {
      StaticRoutes: `/` | `/(tabs)` | `/(tabs)/` | `/(tabs)/learn` | `/(tabs)/profile` | `/(tabs)/progress` | `/_sitemap` | `/auth/forgot-password` | `/auth/login` | `/auth/register` | `/auth/reset-password` | `/learn` | `/profile` | `/progress`;
      DynamicRoutes: never;
      DynamicRouteTemplate: never;
    }
  }
}
