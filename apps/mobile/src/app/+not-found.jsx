import React from 'react';
import { router } from 'expo-router';
import { AppButton, Screen } from '../components/Ui';

export default function NotFoundRoute() {
  return <Screen title="Page not found" subtitle="Return to your StorePro dashboard."><AppButton title="Go to dashboard" icon="home-outline" onPress={() => router.replace('/')} /></Screen>;
}