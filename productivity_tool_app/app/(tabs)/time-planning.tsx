/**
 * Time Planning Tab Screen
 * Displays a calendar view with time blocks for task scheduling
 */

import { useCallback, useMemo, useState } from "react";
import {
  FlatList,
  Pressable,
  StyleSheet,
  View,
  Dimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useTimeBlocks } from "@/hooks/use-storage";
import { Colors, Spacing, BorderRadius, categoryColors } from "@/constants/theme";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { TimeBlock } from "@/lib/types";

const SCREEN_WIDTH = Dimensions.get("window").width;
const HOUR_HEIGHT = 60;
const HOURS_IN_DAY = 24;

export default function TimePlanningScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const colors = Colors[colorScheme ?? "light"];
  const { timeBlocks, getTimeBlocksForDate } = useTimeBlocks();
  const [selectedDate, setSelectedDate] = useState(new Date());

  // Get time blocks for selected date
  const dayBlocks = useMemo(() => {
    return getTimeBlocksForDate(selectedDate).sort((a, b) => 
      a.startTime.getTime() - b.startTime.getTime()
    );
  }, [selectedDate, getTimeBlocksForDate]);

  // Generate week dates
  const weekDates = useMemo(() => {
    const dates = [];
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay());

    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek);
      date.setDate(startOfWeek.getDate() + i);
      dates.push(date);
    }
    return dates;
  }, []);

  const handleDateSelect = useCallback((date: Date) => {
    setSelectedDate(new Date(date));
  }, []);

  const renderWeekDay = useCallback(
    ({ item: date }: { item: Date }) => {
      const isSelected = 
        date.toDateString() === selectedDate.toDateString();
      const isToday = date.toDateString() === new Date().toDateString();

      return (
        <Pressable
          onPress={() => handleDateSelect(date)}
          style={({ pressed }) => [
            styles.weekDay,
            isSelected && {
              backgroundColor: colors.tint,
            },
            isToday && !isSelected && {
              borderColor: colors.tint,
              borderWidth: 2,
            },
            pressed && { opacity: 0.7 },
          ]}
        >
          <ThemedText
            style={{
              fontSize: 12,
              color: isSelected ? "#fff" : colors.textTertiary,
              fontWeight: "600",
            }}
          >
            {date.toLocaleDateString("en-US", { weekday: "short" }).substring(0, 1)}
          </ThemedText>
          <ThemedText
            style={{
              fontSize: 14,
              fontWeight: "bold",
              color: isSelected ? "#fff" : colors.text,
              marginTop: 4,
            }}
          >
            {date.getDate()}
          </ThemedText>
        </Pressable>
      );
    },
    [selectedDate, colors, handleDateSelect],
  );

  const renderTimeBlock = useCallback(
    (block: TimeBlock) => {
      const startHour = block.startTime.getHours();
      const startMinutes = block.startTime.getMinutes();
      const endHour = block.endTime.getHours();
      const endMinutes = block.endTime.getMinutes();

      const topOffset = (startHour + startMinutes / 60) * HOUR_HEIGHT;
      const height = ((endHour - startHour) * 60 + (endMinutes - startMinutes)) / 60 * HOUR_HEIGHT;
      const blockColor = categoryColors[block.category];

      return (
        <Pressable
          key={block.id}
          style={[
            styles.timeBlockItem,
            {
              top: topOffset,
              height: Math.max(height, 40),
              backgroundColor: blockColor,
            },
          ]}
        >
          <ThemedText
            style={{
              fontSize: 11,
              fontWeight: "600",
              color: "#fff",
              padding: 4,
            }}
          >
            {block.startTime.toLocaleTimeString("en-US", {
              hour: "2-digit",
              minute: "2-digit",
              hour12: true,
            })}
          </ThemedText>
        </Pressable>
      );
    },
    [],
  );

  const renderHourRow = useCallback(
    (hour: number) => (
      <View key={hour} style={styles.hourRow}>
        <ThemedText
          style={{
            width: 40,
            fontSize: 11,
            color: colors.textTertiary,
            fontWeight: "500",
          }}
        >
          {hour === 0 ? "12 AM" : hour < 12 ? `${hour} AM` : hour === 12 ? "12 PM" : `${hour - 12} PM`}
        </ThemedText>
        <View
          style={[
            styles.hourLine,
            {
              backgroundColor: colors.border,
            },
          ]}
        />
      </View>
    ),
    [colors],
  );

  return (
    <ThemedView style={[styles.container, { paddingTop: Math.max(insets.top, Spacing.lg) }]}>
      {/* Header */}
      <View style={styles.header}>
        <ThemedText type="title">Time Planning</ThemedText>
      </View>

      {/* Week selector */}
      <FlatList
        horizontal
        data={weekDates}
        keyExtractor={(item) => item.toISOString()}
        renderItem={renderWeekDay}
        contentContainerStyle={styles.weekContainer}
        scrollEnabled={false}
      />

      {/* Selected date info */}
      <View style={[styles.dateInfo, { borderBottomColor: colors.border, borderBottomWidth: 1 }]}>
        <ThemedText type="subtitle">
          {selectedDate.toLocaleDateString("en-US", {
            weekday: "long",
            month: "long",
            day: "numeric",
          })}
        </ThemedText>
        <ThemedText style={{ color: colors.textTertiary, marginTop: 4 }}>
          {dayBlocks.length} block{dayBlocks.length !== 1 ? "s" : ""} scheduled
        </ThemedText>
      </View>

      {/* Time grid */}
      <View style={styles.timeGridContainer}>
        <View style={styles.timeGrid}>
          {/* Hour labels and lines */}
          {Array.from({ length: HOURS_IN_DAY }).map((_, hour) => renderHourRow(hour))}

          {/* Time blocks */}
          <View style={styles.blocksContainer}>
            {dayBlocks.map(renderTimeBlock)}
          </View>
        </View>
      </View>

      {/* Floating action button */}
      <Pressable
        onPress={() => {
          // TODO: Open time block editor
          console.log("Add time block");
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
  weekContainer: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
    gap: Spacing.sm,
  },
  weekDay: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.sm,
    borderRadius: BorderRadius.md,
  },
  dateInfo: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  timeGridContainer: {
    flex: 1,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  timeGrid: {
    flex: 1,
    position: "relative",
  },
  hourRow: {
    flexDirection: "row",
    alignItems: "center",
    height: HOUR_HEIGHT,
    marginBottom: 0,
  },
  hourLine: {
    flex: 1,
    height: 1,
    marginLeft: Spacing.md,
  },
  blocksContainer: {
    ...StyleSheet.absoluteFillObject,
    paddingLeft: 40 + Spacing.md,
  },
  timeBlockItem: {
    position: "absolute",
    left: 0,
    right: Spacing.sm,
    borderRadius: BorderRadius.md,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
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
