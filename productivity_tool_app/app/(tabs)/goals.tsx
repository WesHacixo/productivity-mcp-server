/**
 * Goals Tab Screen
 * Displays goals with progress tracking and milestone management
 */

import { useCallback, useMemo, useState } from "react";
import {
  FlatList,
  Pressable,
  StyleSheet,
  View,
} from "react-native";
import Svg, { Circle } from "react-native-svg";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useGoals } from "@/hooks/use-storage";
import { useGoalsAPI } from "@/hooks/use-goals-api";

// Use API hook by default, fallback to local storage
const USE_API = process.env.EXPO_PUBLIC_USE_API !== "false";
import { Colors, Spacing, BorderRadius, Shadows } from "@/constants/theme";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { Goal } from "@/lib/types";

const PROGRESS_RING_SIZE = 100;
const PROGRESS_RING_STROKE = 8;

export default function GoalsScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const colors = Colors[colorScheme ?? "light"];
  // Use API if enabled, otherwise use local storage
  const apiGoals = useGoalsAPI();
  const localGoals = useGoals();
  const { goals, getActiveGoals, updateGoal } = USE_API ? apiGoals : localGoals;
  const [showArchived, setShowArchived] = useState(false);

  // Filter goals based on archived status
  const displayedGoals = useMemo(() => {
    if (showArchived) {
      return goals.filter((g) => g.archived);
    }
    return getActiveGoals();
  }, [goals, showArchived, getActiveGoals]);

  const handleGoalPress = useCallback((goalId: string) => {
    // TODO: Navigate to goal detail screen
    console.log("Goal pressed:", goalId);
  }, []);

  const handleArchiveGoal = useCallback(
    async (goalId: string, archived: boolean) => {
      await updateGoal(goalId, { archived: !archived });
    },
    [updateGoal],
  );

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
          <ThemedText style={{ fontSize: 18, fontWeight: "bold" }}>
            {Math.round(progress)}%
          </ThemedText>
        </View>
      </View>
    );
  }, [colors]);

  const renderGoalCard = useCallback(
    ({ item: goal }: { item: Goal }) => {
      const daysRemaining = Math.ceil(
        (goal.targetDate.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24),
      );
      const completedMilestones = goal.milestones.filter((m) => m.completed).length;

      return (
        <Pressable
          onPress={() => handleGoalPress(goal.id)}
          style={({ pressed }) => [
            styles.goalCard,
            {
              backgroundColor: colors.surface,
              ...Shadows.md,
              opacity: pressed ? 0.7 : 1,
            },
          ]}
        >
          <View style={styles.goalCardContent}>
            {/* Left: Progress ring */}
            <View style={styles.progressSection}>
              {renderProgressRing(goal.progress)}
            </View>

            {/* Right: Goal info */}
            <View style={styles.goalInfo}>
              <ThemedText type="defaultSemiBold" numberOfLines={2}>
                {goal.title}
              </ThemedText>

              {/* Milestones */}
              <View style={styles.milestoneInfo}>
                <ThemedText style={{ fontSize: 12, color: colors.textTertiary }}>
                  {completedMilestones} of {goal.milestones.length} milestones
                </ThemedText>
              </View>

              {/* Timeline */}
              <View style={styles.timelineInfo}>
                {daysRemaining > 0 ? (
                  <ThemedText style={{ fontSize: 12, color: colors.success }}>
                    {daysRemaining} days left
                  </ThemedText>
                ) : (
                  <ThemedText style={{ fontSize: 12, color: colors.danger }}>
                    Overdue
                  </ThemedText>
                )}
              </View>

              {/* Archive button */}
              <Pressable
                onPress={() => handleArchiveGoal(goal.id, goal.archived)}
                style={({ pressed }) => [
                  styles.archiveButton,
                  { opacity: pressed ? 0.6 : 1 },
                ]}
              >
                <ThemedText style={{ fontSize: 12, color: colors.textTertiary }}>
                  {goal.archived ? "Restore" : "Archive"}
                </ThemedText>
              </Pressable>
            </View>
          </View>
        </Pressable>
      );
    },
    [colors, handleGoalPress, handleArchiveGoal, renderProgressRing],
  );

  return (
    <ThemedView style={[styles.container, { paddingTop: Math.max(insets.top, Spacing.lg) }]}>
      {/* Header */}
      <View style={styles.header}>
        <ThemedText type="title">Goals</ThemedText>
      </View>

      {/* Toggle archived */}
      <View style={styles.toggleContainer}>
        <Pressable
          onPress={() => setShowArchived(false)}
          style={({ pressed }) => [
            styles.toggleButton,
            !showArchived && { backgroundColor: colors.tint },
            pressed && { opacity: 0.7 },
          ]}
        >
          <ThemedText
            style={{
              color: !showArchived ? "#fff" : colors.text,
              fontWeight: "600",
              fontSize: 12,
            }}
          >
            Active ({getActiveGoals().length})
          </ThemedText>
        </Pressable>

        <Pressable
          onPress={() => setShowArchived(true)}
          style={({ pressed }) => [
            styles.toggleButton,
            showArchived && { backgroundColor: colors.tint },
            pressed && { opacity: 0.7 },
          ]}
        >
          <ThemedText
            style={{
              color: showArchived ? "#fff" : colors.text,
              fontWeight: "600",
              fontSize: 12,
            }}
          >
            Archived ({goals.filter((g) => g.archived).length})
          </ThemedText>
        </Pressable>
      </View>

      {/* Goals list */}
      <FlatList
        data={displayedGoals}
        keyExtractor={(item) => item.id}
        renderItem={renderGoalCard}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <ThemedText type="subtitle" style={{ color: colors.textTertiary }}>
              {showArchived ? "No archived goals" : "No active goals"}
            </ThemedText>
            <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm, fontSize: 12 }}>
              {showArchived ? "Create a new goal to get started" : "Create your first goal"}
            </ThemedText>
          </View>
        }
      />

      {/* Floating action button */}
      {!showArchived && (
        <Pressable
          onPress={() => {
            // TODO: Open new goal sheet
            console.log("Add goal");
          }}
          style={({ pressed }) => [
            styles.fab,
            {
              backgroundColor: colors.tint,
              opacity: pressed ? 0.8 : 1,
            },
          ]}
        >
          <ThemedText style={{ fontSize: 28, color: "#fff" }}>+</ThemedText>
        </Pressable>
      )}
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
  },
  toggleContainer: {
    flexDirection: "row",
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
    gap: Spacing.md,
  },
  toggleButton: {
    flex: 1,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.md,
    borderRadius: BorderRadius.md,
    alignItems: "center",
    justifyContent: "center",
  },
  listContent: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: 100, // Space for FAB
    gap: Spacing.lg,
  },
  goalCard: {
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
  },
  goalCardContent: {
    flexDirection: "row",
    gap: Spacing.lg,
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
  goalInfo: {
    flex: 1,
    justifyContent: "space-between",
  },
  milestoneInfo: {
    marginTop: Spacing.sm,
  },
  timelineInfo: {
    marginTop: Spacing.xs,
  },
  archiveButton: {
    marginTop: Spacing.md,
  },
  emptyState: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 60,
  },
  fab: {
    position: "absolute",
    bottom: Spacing.xl,
    right: Spacing.lg,
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: "center",
    alignItems: "center",
  },
});
