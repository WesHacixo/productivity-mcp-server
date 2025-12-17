/**
 * Home Dashboard Screen
 * Overview of today's tasks, active goals, and time allocation
 */

import { useCallback, useMemo } from "react";
import {
  ScrollView,
  Pressable,
  StyleSheet,
  View,
} from "react-native";
import Svg, { Circle } from "react-native-svg";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useTasks, useGoals, useTimeBlocks } from "@/hooks/use-storage";
import { Colors, Spacing, BorderRadius, Shadows } from "@/constants/theme";
import { useColorScheme } from "@/hooks/use-color-scheme";

const PROGRESS_RING_SIZE = 120;
const PROGRESS_RING_STROKE = 10;

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const colors = Colors[colorScheme ?? "light"];
  const { tasks, getTodaysTasks } = useTasks();
  const { getActiveGoals } = useGoals();
  const { getTimeBlocksForDate } = useTimeBlocks();

  // Calculate today's stats
  const todaysTasks = useMemo(() => getTodaysTasks(), [getTodaysTasks]);
  const completedTodayCount = useMemo(() => todaysTasks.filter((t) => t.completed).length, [todaysTasks]);
  const todaysProgress = useMemo(() => 
    todaysTasks.length > 0 ? Math.round((completedTodayCount / todaysTasks.length) * 100) : 0,
    [todaysTasks, completedTodayCount]
  );

  // Get active goals
  const activeGoals = useMemo(() => getActiveGoals(), [getActiveGoals]);

  // Get today's time blocks
  const todaysBlocks = useMemo(() => getTimeBlocksForDate(new Date()), [getTimeBlocksForDate]);
  const nextBlock = useMemo(() => {
    const now = new Date();
    return todaysBlocks.find((b) => b.startTime > now);
  }, [todaysBlocks]);

  const renderProgressRing = useCallback((progress: number) => {
    const radius = (PROGRESS_RING_SIZE - PROGRESS_RING_STROKE) / 2;
    const circumference = radius * 2 * Math.PI;
    const strokeDashoffset = circumference - (progress / 100) * circumference;

    return (
      <View style={styles.progressRingContainer}>
        <Svg width={PROGRESS_RING_SIZE} height={PROGRESS_RING_SIZE}>
          {/* Background circle */}
          <Circle
            stroke={colors.surface}
            fill="none"
            cx={PROGRESS_RING_SIZE / 2}
            cy={PROGRESS_RING_SIZE / 2}
            r={radius}
            strokeWidth={PROGRESS_RING_STROKE}
          />
          {/* Progress circle */}
          <Circle
            stroke={colors.success}
            fill="none"
            cx={PROGRESS_RING_SIZE / 2}
            cy={PROGRESS_RING_SIZE / 2}
            r={radius}
            strokeWidth={PROGRESS_RING_STROKE}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            rotation="-90"
            origin={`${PROGRESS_RING_SIZE / 2}, ${PROGRESS_RING_SIZE / 2}`}
          />
        </Svg>
        <View style={styles.progressText}>
          <ThemedText style={{ fontSize: 24, fontWeight: "bold" }}>
            {Math.round(progress)}%
          </ThemedText>
        </View>
      </View>
    );
  }, [colors]);

  return (
    <ThemedView style={[styles.container, { paddingTop: Math.max(insets.top, Spacing.lg) }]}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <ThemedText type="title">Today</ThemedText>
          <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm }}>
            {new Date().toLocaleDateString("en-US", {
              weekday: "long",
              month: "long",
              day: "numeric",
            })}
          </ThemedText>
        </View>

        {/* Today's Progress Card */}
        <View
          style={[
            styles.card,
            {
              backgroundColor: colors.surface,
              ...Shadows.md,
            },
          ]}
        >
          <View style={styles.cardContent}>
            <View style={styles.progressSection}>
              {renderProgressRing(todaysProgress)}
            </View>
            <View style={styles.progressInfo}>
              <ThemedText type="subtitle">Today's Tasks</ThemedText>
              <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm }}>
                {completedTodayCount} of {todaysTasks.length} completed
              </ThemedText>
              <Pressable
                onPress={() => console.log("View all tasks")}
                style={({ pressed }) => [
                  styles.actionButton,
                  { opacity: pressed ? 0.7 : 1 },
                ]}
              >
                <ThemedText style={{ color: colors.tint, fontWeight: "600", fontSize: 12 }}>
                  View All →
                </ThemedText>
              </Pressable>
            </View>
          </View>
        </View>

        {/* Next Time Block */}
        {nextBlock && (
          <View
            style={[
              styles.card,
              {
                backgroundColor: colors.surface,
                ...Shadows.md,
              },
            ]}
          >
            <ThemedText type="subtitle" style={{ marginBottom: Spacing.md }}>
              Next Scheduled
            </ThemedText>
            <View style={styles.timeBlockInfo}>
              <ThemedText type="defaultSemiBold">
                {nextBlock.startTime.toLocaleTimeString("en-US", {
                  hour: "2-digit",
                  minute: "2-digit",
                  hour12: true,
                })}
              </ThemedText>
              <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm }}>
                {Math.round((nextBlock.endTime.getTime() - nextBlock.startTime.getTime()) / 60000)} minutes
              </ThemedText>
            </View>
          </View>
        )}

        {/* Active Goals Preview */}
        {activeGoals.length > 0 && (
          <View>
            <ThemedText type="subtitle" style={{ marginBottom: Spacing.md }}>
              Active Goals
            </ThemedText>
            {activeGoals.slice(0, 2).map((goal) => (
              <View
                key={goal.id}
                style={[
                  styles.goalPreview,
                  {
                    backgroundColor: colors.surface,
                    ...Shadows.sm,
                  },
                ]}
              >
                <View style={styles.goalPreviewContent}>
                  <ThemedText type="defaultSemiBold" numberOfLines={1}>
                    {goal.title}
                  </ThemedText>
                  <View style={styles.goalProgressBar}>
                    <View
                      style={[
                        styles.goalProgressFill,
                        {
                          width: `${goal.progress}%`,
                          backgroundColor: colors.success,
                        },
                      ]}
                    />
                  </View>
                  <ThemedText style={{ fontSize: 12, color: colors.textTertiary, marginTop: Spacing.sm }}>
                    {goal.progress}% complete
                  </ThemedText>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.quickActionsContainer}>
          <ThemedText type="subtitle" style={{ marginBottom: Spacing.md }}>
            Quick Actions
          </ThemedText>
          <View style={styles.quickActions}>
            <Pressable
              onPress={() => console.log("Add task")}
              style={({ pressed }) => [
                styles.quickActionButton,
                {
                  backgroundColor: colors.tint,
                  opacity: pressed ? 0.8 : 1,
                },
              ]}
            >
              <ThemedText style={{ fontSize: 20 }}>➕</ThemedText>
              <ThemedText style={{ color: "#fff", fontSize: 12, marginTop: Spacing.xs }}>
                Task
              </ThemedText>
            </Pressable>

            <Pressable
              onPress={() => console.log("Start timer")}
              style={({ pressed }) => [
                styles.quickActionButton,
                {
                  backgroundColor: colors.warning,
                  opacity: pressed ? 0.8 : 1,
                },
              ]}
            >
              <ThemedText style={{ fontSize: 20 }}>⏱️</ThemedText>
              <ThemedText style={{ color: "#fff", fontSize: 12, marginTop: Spacing.xs }}>
                Timer
              </ThemedText>
            </Pressable>

            <Pressable
              onPress={() => console.log("Log file")}
              style={({ pressed }) => [
                styles.quickActionButton,
                {
                  backgroundColor: colors.neutral,
                  opacity: pressed ? 0.8 : 1,
                },
              ]}
            >
              <ThemedText style={{ fontSize: 20 }}>📎</ThemedText>
              <ThemedText style={{ color: "#fff", fontSize: 12, marginTop: Spacing.xs }}>
                File
              </ThemedText>
            </Pressable>
          </View>
        </View>
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.xl,
  },
  header: {
    marginBottom: Spacing.xl,
  },
  card: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
    marginBottom: Spacing.lg,
  },
  cardContent: {
    flexDirection: "row",
    gap: Spacing.lg,
    alignItems: "center",
  },
  progressSection: {
    justifyContent: "center",
    alignItems: "center",
  },
  progressRingContainer: {
    position: "relative",
    justifyContent: "center",
    alignItems: "center",
  },
  progressText: {
    position: "absolute",
    justifyContent: "center",
    alignItems: "center",
  },
  progressInfo: {
    flex: 1,
  },
  actionButton: {
    marginTop: Spacing.md,
  },
  timeBlockInfo: {
    paddingVertical: Spacing.md,
  },
  goalPreview: {
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    marginBottom: Spacing.md,
  },
  goalPreviewContent: {
    gap: Spacing.sm,
  },
  goalProgressBar: {
    height: 6,
    backgroundColor: "rgba(0,0,0,0.1)",
    borderRadius: 3,
    marginTop: Spacing.sm,
    overflow: "hidden",
  },
  goalProgressFill: {
    height: "100%",
    borderRadius: 3,
  },
  quickActionsContainer: {
    marginTop: Spacing.xl,
  },
  quickActions: {
    flexDirection: "row",
    gap: Spacing.md,
  },
  quickActionButton: {
    flex: 1,
    paddingVertical: Spacing.lg,
    borderRadius: BorderRadius.md,
    alignItems: "center",
    justifyContent: "center",
  },
});
