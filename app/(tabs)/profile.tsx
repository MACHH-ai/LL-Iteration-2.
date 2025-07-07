import React from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  TouchableOpacity,
  Switch,
  Alert
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { User, Settings, Bell, Shield, HelpCircle, LogOut, Camera, Moon, Volume2, Monitor, Users, Crown, ChevronRight } from 'lucide-react-native';
import { router } from 'expo-router';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const { colors, theme, toggleTheme } = useTheme();

  const handleLogout = () => {
    Alert.alert(
      "Sign Out",
      "Are you sure you want to sign out?",
      [
        { text: "Cancel", style: "cancel" },
        { text: "Sign Out", style: "destructive", onPress: logout }
      ]
    );
  };

  const settingsGroups = [
    {
      title: "Account",
      items: [
        { icon: User, label: "Edit Profile", onPress: () => {} },
        { icon: Camera, label: "Change Avatar", onPress: () => {} },
        { icon: Crown, label: "Upgrade to Premium", onPress: () => {}, premium: true },
      ]
    },
    {
      title: "Preferences",
      items: [
        { icon: Bell, label: "Notifications", toggle: true, value: true },
        { icon: Volume2, label: "Sound Effects", toggle: true, value: true },
        { icon: Moon, label: "Dark Mode", toggle: true, value: theme === 'dark', onToggle: toggleTheme },
      ]
    },
    {
      title: "Family",
      items: [
        { icon: Users, label: "Parent Dashboard", onPress: () => {} },
        { icon: Shield, label: "Screen Time Controls", onPress: () => {} },
        { icon: Monitor, label: "Teacher Portal", onPress: () => {} },
      ]
    },
    {
      title: "Support",
      items: [
        { icon: HelpCircle, label: "Help Center", onPress: () => {} },
        { icon: Settings, label: "App Settings", onPress: () => {} },
        { icon: LogOut, label: "Sign Out", onPress: handleLogout, danger: true },
      ]
    }
  ];

  return (
    <ScrollView style={[styles.container, { backgroundColor: colors.background }]} showsVerticalScrollIndicator={false}>
      <LinearGradient
        colors={[colors.primary, '#6366F1']}
        style={styles.header}
      >
        <View style={styles.profileSection}>
          <View style={styles.avatarContainer}>
            <View style={[styles.avatar, { backgroundColor: 'rgba(255,255,255,0.1)', borderColor: colors.surface }]}>
              <Text style={[styles.avatarText, { color: colors.text }]}>
                {user?.firstName?.[0]}{user?.lastName?.[0]}
              </Text>
            </View>
            <View style={[styles.statusIndicator, { backgroundColor: '#10B981', borderColor: colors.surface }]} />
          </View>
          <Text style={[styles.userName, { color: colors.text }]}>
            {user?.firstName} {user?.lastName}
          </Text>
          {!user?.isGuest && (
            <Text style={[styles.userEmail, { color: colors.textSecondary }]}>{user?.email}</Text>
          )}
          {user?.isGuest && (
            <Text style={[styles.guestLabel, { color: '#F59E0B' }]}>Guest User</Text>
          )}
          <View style={[styles.levelContainer, { backgroundColor: 'rgba(255,255,255,0.1)' }]}>
            <Text style={[styles.levelText, { color: colors.text }]}>Level 12 • Learning Explorer</Text>
          </View>
        </View>

        <View style={[styles.statsRow, { backgroundColor: 'rgba(255,255,255,0.1)' }]}>
          <View style={styles.statItem}>
            <Text style={[styles.statNumber, { color: colors.text }]}>127</Text>
            <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Problems Solved</Text>
          </View>
          <View style={[styles.statDivider, { backgroundColor: 'rgba(255,255,255,0.1)' }]} />
          <View style={styles.statItem}>
            <Text style={[styles.statNumber, { color: colors.text }]}>42</Text>
            <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Hours Learned</Text>
          </View>
          <View style={[styles.statDivider, { backgroundColor: 'rgba(255,255,255,0.1)' }]} />
          <View style={styles.statItem}>
            <Text style={[styles.statNumber, { color: colors.text }]}>7</Text>
            <Text style={[styles.statLabel, { color: colors.textSecondary }]}>Day Streak</Text>
          </View>
        </View>
      </LinearGradient>

      <View style={styles.content}>
        {settingsGroups.map((group, groupIndex) => (
          <View key={groupIndex} style={styles.settingsGroup}>
            <Text style={[styles.groupTitle, { color: colors.text }]}>{group.title}</Text>
            <View style={[styles.groupContainer, { backgroundColor: colors.surface }]}>
              {group.items.map((item, itemIndex) => (
                <TouchableOpacity
                  key={itemIndex}
                  style={[
                    styles.settingsItem,
                    itemIndex === group.items.length - 1 && styles.lastItem,
                    { borderBottomColor: colors.border }
                  ]}
                  onPress={item.onPress}
                  disabled={item.toggle && !item.onToggle}
                >
                  <View style={styles.settingsItemLeft}>
                    <View style={[
                      styles.settingsIcon,
                      { backgroundColor: colors.surfaceSecondary },
                      item.danger && { backgroundColor: '#EF4444' + '20' },
                      item.premium && { backgroundColor: '#F59E0B' + '20' }
                    ]}>
                      <item.icon 
                        size={20} 
                        color={item.danger ? '#EF4444' : item.premium ? '#F59E0B' : colors.textSecondary} 
                      />
                    </View>
                    <Text style={[
                      styles.settingsLabel,
                      { color: colors.text },
                      item.danger && { color: '#EF4444' },
                      item.premium && { color: '#F59E0B' }
                    ]}>
                      {item.label}
                    </Text>
                  </View>
                  
                  {item.toggle ? (
                    <Switch
                      value={item.value || false}
                      onValueChange={item.onToggle || (() => {})}
                      trackColor={{ false: colors.border, true: colors.primary }}
                      thumbColor={item.value ? '#FFF' : '#FFF'}
                    />
                  ) : (
                    <ChevronRight size={16} color={colors.textTertiary} />
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ))}

        <View style={styles.footerSection}>
          <Text style={[styles.footerText, { color: colors.textSecondary }]}>Luminara Learn v1.0.0</Text>
          <Text style={[styles.footerSubtext, { color: colors.textTertiary }]}>
            Illuminating the path to understanding
          </Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: 60,
    paddingBottom: 30,
    paddingHorizontal: 20,
  },
  profileSection: {
    alignItems: 'center',
    marginBottom: 30,
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
  },
  avatarText: {
    fontSize: 24,
    fontWeight: '700',
  },
  statusIndicator: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 2,
  },
  userName: {
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 4,
  },
  userEmail: {
    fontSize: 16,
    marginBottom: 12,
  },
  guestLabel: {
    fontSize: 16,
    marginBottom: 12,
    fontStyle: 'italic',
  },
  levelContainer: {
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 20,
  },
  levelText: {
    fontSize: 14,
    fontWeight: '600',
  },
  statsRow: {
    flexDirection: 'row',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
    flex: 1,
  },
  statNumber: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    textAlign: 'center',
  },
  statDivider: {
    width: 1,
    height: 30,
  },
  content: {
    padding: 20,
  },
  settingsGroup: {
    marginBottom: 24,
  },
  groupTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 12,
    marginLeft: 4,
  },
  groupContainer: {
    borderRadius: 16,
    overflow: 'hidden',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  settingsItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderBottomWidth: 1,
  },
  lastItem: {
    borderBottomWidth: 0,
  },
  settingsItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  settingsIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  settingsLabel: {
    fontSize: 16,
    fontWeight: '500',
  },
  footerSection: {
    alignItems: 'center',
    marginTop: 20,
    paddingBottom: 20,
  },
  footerText: {
    fontSize: 14,
    marginBottom: 4,
  },
  footerSubtext: {
    fontSize: 12,
    fontStyle: 'italic',
  },
});