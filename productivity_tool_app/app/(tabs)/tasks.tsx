/**
 * Tasks Tab Screen
 * Displays a list of tasks with filtering, searching, and management options
 */

import { useCallback, useMemo, useState } from "react";
import {
  FlatList,
  Pressable,
  StyleSheet,
  TextInput,
  View,
  RefreshControl,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useThemeColor } from "@/hooks/use-theme-color";
import { useTasks } from "@/hooks/use-storage";
import { useTasksAPI } from "@/hooks/use-tasks-api";

// Use API hook by default, fallback to local storage
const USE_API = process.env.EXPO_PUBLIC_USE_API !== "false";
import { Colors, Spacing, BorderRadius, Typography, getPriorityColor } from "@/constants/theme";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { Task } from "@/lib/types";
import { router } from "expo-router";

type FilterType = "all" | "today" | "overdue" | "completed";

export default function TasksScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const colors = Colors[colorScheme ?? "light"];
  // Use API if enabled, otherwise use local storage
  const apiTasks = useTasksAPI();
  const localTasks = useTasks();
  const { tasks, getTodaysTasks, getOverdueTasks, updateTask, loading } = USE_API ? apiTasks : localTasks;
  const [filter, setFilter] = useState<FilterType>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [refreshing, setRefreshing] = useState(false);

  // Filter tasks based on selected filter
  const filteredTasks = useMemo(() => {
    let result: Task[] = [];

    switch (filter) {
      case "today":
        result = getTodaysTasks();
        break;
      case "overdue":
        result = getOverdueTasks();
        break;
      case "completed":
        result = tasks.filter((t) => t.completed);
        break;
      default:
        result = tasks;
    }

    // Apply search filter
    if (searchQuery.trim()) {
      result = result.filter((t) =>
        t.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        t.description.toLowerCase().includes(searchQuery.toLowerCase()),
      );
    }

    return result.sort((a, b) => {
      // Sort by priority first (high to low)
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      // Then by due date
      return a.dueDate.getTime() - b.dueDate.getTime();
    });
  }, [tasks, filter, searchQuery, getTodaysTasks, getOverdueTasks]);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    // Simulate refresh delay
    await new Promise((resolve) => setTimeout(resolve, 500));
    setRefreshing(false);
  }, []);

  const handleTaskPress = useCallback(
    (taskId: string) => {
      // TODO: Create task-detail screen
      // For now, just log the task ID
      console.log("Task pressed:", taskId);
    },
    [],
  );

  const handleToggleComplete = useCallback(
    async (taskId: string, completed: boolean) => {
      await updateTask(taskId, {
        completed: !completed,
        completedAt: !completed ? new Date() : undefined,
      });
    },
    [updateTask],
  );

  const renderTaskItem = useCallback(
    ({ item: task }: { item: Task }) => {
      const priorityColor = getPriorityColor(
        task.priority === 1 ? "high" : task.priority === 2 ? "medium" : task.priority === 3 ? "low" : "minimal",
      );
      const isOverdue = !task.completed && task.dueDate < new Date();

      return (
        <Pressable
          onPress={() => handleTaskPress(task.id)}
          style={({ pressed }) => [
            styles.taskItem,
            {
              backgroundColor: colors.surface,
              borderColor: colors.border,
              opacity: pressed ? 0.7 : 1,
            },
          ]}
        >
          <View style={styles.taskContent}>
            {/* Priority indicator */}
            <View
              style={[
                styles.priorityDot,
                {
                  backgroundColor: priorityColor,
                },
              ]}
            />

            {/* Task info */}
            <View style={styles.taskInfo}>
              <ThemedText
                type="defaultSemiBold"
                style={[
                  styles.taskTitle,
                  task.completed && { textDecorationLine: "line-through", opacity: 0.6 },
                ]}
              >
                {task.title}
              </ThemedText>
              <View style={styles.taskMeta}>
                <ThemedText style={{ color: colors.textTertiary, fontSize: 12 }}>
                  {task.dueDate.toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                  })}
                </ThemedText>
                {task.estimatedDuration > 0 && (
                  <ThemedText style={{ color: colors.textTertiary, marginLeft: Spacing.sm, fontSize: 12 }}>
                    {Math.floor(task.estimatedDuration / 60)}h {task.estimatedDuration % 60}m
                  </ThemedText>
                )}
                {task.attachments.length > 0 && (
                  <ThemedText style={{ color: colors.textTertiary, marginLeft: Spacing.sm, fontSize: 12 }}>
                    📎 {task.attachments.length}
                  </ThemedText>
                )}
              </View>
            </View>

            {/* Completion checkbox */}
            <Pressable
              onPress={() => handleToggleComplete(task.id, task.completed)}
              style={({ pressed }) => [
                styles.checkbox,
                {
                  backgroundColor: task.completed ? colors.success : colors.surface,
                  borderColor: task.completed ? colors.success : colors.border,
                  opacity: pressed ? 0.7 : 1,
                },
              ]}
            >
              {task.completed && <ThemedText style={{ color: "#fff", fontWeight: "bold" }}>✓</ThemedText>}
            </Pressable>
          </View>

          {/* Overdue indicator */}
          {isOverdue && (
            <View
              style={[
                styles.overdueIndicator,
                {
                  backgroundColor: colors.danger,
                },
              ]}
            />
          )}
        </Pressable>
      );
    },
    [colors, handleTaskPress, handleToggleComplete],
  );

  return (
    <ThemedView style={[styles.container, { paddingTop: Math.max(insets.top, Spacing.lg) }]}>
      {/* Header */}
      <View style={styles.header}>
        <ThemedText type="title" style={styles.headerTitle}>
          Tasks
        </ThemedText>
      </View>

      {/* Search bar */}
      <View
        style={[
          styles.searchContainer,
          {
            backgroundColor: colors.surface,
            borderColor: colors.border,
          },
        ]}
      >
        <ThemedText style={{ color: colors.textTertiary }}>🔍</ThemedText>
        <TextInput
          placeholder="Search tasks..."
          placeholderTextColor={colors.textTertiary}
          value={searchQuery}
          onChangeText={setSearchQuery}
          style={[
            styles.searchInput,
            {
              color: colors.text,
            },
          ]}
        />
      </View>

      {/* Filter tabs */}
      <View style={styles.filterContainer}>
        {(["all", "today", "overdue", "completed"] as const).map((filterOption) => (
          <Pressable
            key={filterOption}
            onPress={() => setFilter(filterOption)}
            style={({ pressed }) => [
              styles.filterButton,
              filter === filterOption && {
                backgroundColor: colors.tint,
              },
              filter !== filterOption && {
                backgroundColor: colors.surface,
              },
              pressed && { opacity: 0.7 },
            ]}
          >
            <ThemedText
              style={{
                color: filter === filterOption ? "#fff" : colors.text,
                fontWeight: "600",
                fontSize: 12,
              }}
            >
              {filterOption.charAt(0).toUpperCase() + filterOption.slice(1)}
            </ThemedText>
          </Pressable>
        ))}
      </View>

      {/* Task list */}
      <FlatList
        data={filteredTasks}
        keyExtractor={(item) => item.id}
        renderItem={renderTaskItem}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <ThemedText type="subtitle" style={{ color: colors.textTertiary }}>
              {searchQuery ? "No tasks found" : "No tasks yet"}
            </ThemedText>
      <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm, fontSize: 12 }}>
            {searchQuery ? "Try a different search" : "Create one to get started"}
          </ThemedText>
          </View>
        }
      />

      {/* Floating action button */}
      <Pressable
        onPress={() => router.push("/(tabs)/tasks")}
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
  headerTitle: {
    marginBottom: Spacing.sm,
  },
  searchContainer: {
    flexDirection: "row",
    alignItems: "center",
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.lg,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.md,
    borderWidth: 1,
  },
  searchInput: {
    flex: 1,
    marginLeft: Spacing.md,
    fontSize: 16,
    padding: 0,
  },
  filterContainer: {
    flexDirection: "row",
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
    gap: Spacing.sm,
  },
  filterButton: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.md,
  },
  listContent: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: 100, // Space for FAB
  },
  taskItem: {
    marginBottom: Spacing.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.md,
    borderWidth: 1,
  },
  taskContent: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
  },
  priorityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    marginBottom: Spacing.xs,
  },
  taskMeta: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: BorderRadius.sm,
    borderWidth: 2,
    justifyContent: "center",
    alignItems: "center",
  },
  overdueIndicator: {
    height: 2,
    marginTop: Spacing.md,
    borderRadius: 1,
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
