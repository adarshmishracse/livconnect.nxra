import { StatusBar } from 'expo-status-bar';
import { SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

const stats = [
  { value: '1,248', label: 'Total Members', color: '#2563EB' },
  { value: '86', label: 'Available Seats', color: '#16A34A' },
  { value: '324', label: 'Books Issued', color: '#F97316' },
  { value: '18', label: 'Due Today', color: '#DC2626' },
];

export default function App() {
  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="dark" />
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.header}>
          <View>
            <Text style={styles.greeting}>Welcome back</Text>
            <Text style={styles.title}>Library Dashboard</Text>
          </View>
          <View style={styles.avatar}><Text style={styles.avatarText}>LA</Text></View>
        </View>

        <View style={styles.heroCard}>
          <Text style={styles.heroLabel}>TODAY'S OVERVIEW</Text>
          <Text style={styles.heroTitle}>Everything looks good</Text>
          <Text style={styles.heroText}>Track members, seats, books and payments from one place.</Text>
        </View>

        <Text style={styles.sectionTitle}>Quick Overview</Text>
        <View style={styles.grid}>
          {stats.map((stat) => (
            <View key={stat.label} style={styles.statCard}>
              <View style={[styles.statDot, { backgroundColor: stat.color }]} />
              <Text style={styles.statValue}>{stat.value}</Text>
              <Text style={styles.statLabel}>{stat.label}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.sectionTitle}>Quick Actions</Text>
        <View style={styles.actionRow}>
          <View style={styles.actionCard}><Text style={styles.actionIcon}>+</Text><Text style={styles.actionText}>Add Member</Text></View>
          <View style={styles.actionCard}><Text style={styles.actionIcon}>↗</Text><Text style={styles.actionText}>Issue Book</Text></View>
          <View style={styles.actionCard}><Text style={styles.actionIcon}>✓</Text><Text style={styles.actionText}>Check In</Text></View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#F8FAFC' },
  container: { paddingHorizontal: 20, paddingVertical: 18, paddingBottom: 40 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 },
  greeting: { color: '#64748B', fontSize: 14, marginBottom: 3 },
  title: { color: '#0F172A', fontSize: 25, fontWeight: '700' },
  avatar: { width: 46, height: 46, borderRadius: 23, backgroundColor: '#E2E8F0', alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: '#1E293B', fontWeight: '700' },
  heroCard: { backgroundColor: '#1D4ED8', borderRadius: 18, padding: 22, marginBottom: 24 },
  heroLabel: { color: '#BFDBFE', fontSize: 12, fontWeight: '700', letterSpacing: 1, marginBottom: 8 },
  heroTitle: { color: '#FFFFFF', fontSize: 21, fontWeight: '700', marginBottom: 7 },
  heroText: { color: '#DBEAFE', fontSize: 14, lineHeight: 21 },
  sectionTitle: { color: '#334155', fontSize: 17, fontWeight: '700', marginBottom: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', marginBottom: 24 },
  statCard: { width: '48%', minHeight: 112, backgroundColor: '#FFFFFF', borderRadius: 14, padding: 16, marginBottom: 12, borderWidth: 1, borderColor: '#E2E8F0' },
  statDot: { width: 9, height: 9, borderRadius: 5, marginBottom: 12 },
  statValue: { color: '#0F172A', fontSize: 24, fontWeight: '700', marginBottom: 4 },
  statLabel: { color: '#64748B', fontSize: 13 },
  actionRow: { flexDirection: 'row', justifyContent: 'space-between' },
  actionCard: { width: '31%', height: 100, backgroundColor: '#FFFFFF', borderRadius: 14, borderWidth: 1, borderColor: '#E2E8F0', alignItems: 'center', justifyContent: 'center', paddingHorizontal: 6 },
  actionIcon: { color: '#2563EB', fontSize: 24, fontWeight: '700', marginBottom: 8 },
  actionText: { color: '#334155', fontSize: 12, fontWeight: '600', textAlign: 'center' },
});
