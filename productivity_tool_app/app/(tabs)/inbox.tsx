/**
 * File Inbox Tab Screen
 * Displays files received from share sheet awaiting processing
 */

import { useCallback, useMemo } from "react";
import {
  FlatList,
  Pressable,
  StyleSheet,
  View,
  Image,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ThemedText } from "@/components/themed-text";
import { ThemedView } from "@/components/themed-view";
import { useInboxFiles } from "@/hooks/use-storage";
import { Colors, Spacing, BorderRadius, Shadows } from "@/constants/theme";
import { useColorScheme } from "@/hooks/use-color-scheme";
import { InboxFile } from "@/lib/types";

const FILE_TYPE_ICONS: Record<string, string> = {
  "application/pdf": "📄",
  "image/jpeg": "🖼️",
  "image/png": "🖼️",
  "text/plain": "📝",
  "text/csv": "📊",
  "application/json": "📋",
  "audio/mpeg": "🎵",
  "audio/wav": "🎵",
};

export default function InboxScreen() {
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const colors = Colors[colorScheme ?? "light"];
  const { files, deleteFile, updateFile, getPendingFiles } = useInboxFiles();

  // Separate files by status
  const pendingFiles = useMemo(() => getPendingFiles(), [getPendingFiles]);
  const processedFiles = useMemo(() => files.filter((f) => f.processingStatus !== "pending"), [files]);

  const getFileIcon = (mimeType: string): string => {
    return FILE_TYPE_ICONS[mimeType] || "📎";
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
  };

  const handleFilePress = useCallback((fileId: string) => {
    // TODO: Open file preview and parser sheet
    console.log("File pressed:", fileId);
  }, []);

  const handleDeleteFile = useCallback(
    async (fileId: string) => {
      await deleteFile(fileId);
    },
    [deleteFile],
  );

  const handleLinkToTask = useCallback((fileId: string) => {
    // TODO: Open task picker sheet
    console.log("Link file to task:", fileId);
  }, []);

  const renderFileItem = useCallback(
    ({ item: file }: { item: InboxFile }) => {
      const icon = getFileIcon(file.type);
      const isImage = file.type.startsWith("image/");

      return (
        <Pressable
          onPress={() => handleFilePress(file.id)}
          style={({ pressed }) => [
            styles.fileItem,
            {
              backgroundColor: colors.surface,
              borderColor: colors.border,
              opacity: pressed ? 0.7 : 1,
            },
          ]}
        >
          <View style={styles.fileContent}>
            {/* File preview or icon */}
            {isImage && file.preview ? (
              <Image
                source={{ uri: file.preview }}
                style={styles.filePreview}
              />
            ) : (
              <View
                style={[
                  styles.fileIcon,
                  {
                    backgroundColor: colors.tint,
                  },
                ]}
              >
                <ThemedText style={{ fontSize: 24 }}>{icon}</ThemedText>
              </View>
            )}

            {/* File info */}
            <View style={styles.fileInfo}>
              <ThemedText type="defaultSemiBold" numberOfLines={1}>
                {file.name}
              </ThemedText>
              <View style={styles.fileMeta}>
                <ThemedText style={{ fontSize: 12, color: colors.textTertiary }}>
                  {formatFileSize(file.size)}
                </ThemedText>
                <ThemedText style={{ fontSize: 12, color: colors.textTertiary, marginLeft: Spacing.sm }}>
                  {file.receivedAt.toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </ThemedText>
              </View>

              {/* Status badge */}
              <View style={styles.statusBadge}>
                <ThemedText
                  style={{
                    fontSize: 11,
                    fontWeight: "600",
                    color: 
                      file.processingStatus === "pending"
                        ? colors.warning
                        : file.processingStatus === "parsed"
                        ? colors.success
                        : colors.danger,
                  }}
                >
                  {file.processingStatus.charAt(0).toUpperCase() + file.processingStatus.slice(1)}
                </ThemedText>
              </View>
            </View>

            {/* Actions */}
            <View style={styles.actions}>
              {file.processingStatus === "pending" && (
                <Pressable
                  onPress={() => handleLinkToTask(file.id)}
                  style={({ pressed }) => [{ opacity: pressed ? 0.6 : 1 }]}
                >
                  <ThemedText style={{ fontSize: 18 }}>🔗</ThemedText>
                </Pressable>
              )}
              <Pressable
                onPress={() => handleDeleteFile(file.id)}
                style={({ pressed }) => [{ opacity: pressed ? 0.6 : 1 }]}
              >
                <ThemedText style={{ fontSize: 18 }}>🗑️</ThemedText>
              </Pressable>
            </View>
          </View>
        </Pressable>
      );
    },
    [colors, handleFilePress, handleDeleteFile, handleLinkToTask],
  );

  return (
    <ThemedView style={[styles.container, { paddingTop: Math.max(insets.top, Spacing.lg) }]}>
      {/* Header */}
      <View style={styles.header}>
        <ThemedText type="title">File Inbox</ThemedText>
        {files.length > 0 && (
          <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm }}>
            {files.length} file{files.length !== 1 ? "s" : ""}
          </ThemedText>
        )}
      </View>

      {/* Pending files section */}
      {pendingFiles.length > 0 && (
        <View style={styles.section}>
          <ThemedText type="subtitle" style={styles.sectionTitle}>
            Pending ({pendingFiles.length})
          </ThemedText>
          <FlatList
            data={pendingFiles}
            keyExtractor={(item) => item.id}
            renderItem={renderFileItem}
            scrollEnabled={false}
            contentContainerStyle={styles.listContent}
          />
        </View>
      )}

      {/* Processed files section */}
      {processedFiles.length > 0 && (
        <View style={styles.section}>
          <ThemedText type="subtitle" style={styles.sectionTitle}>
            Processed ({processedFiles.length})
          </ThemedText>
          <FlatList
            data={processedFiles}
            keyExtractor={(item) => item.id}
            renderItem={renderFileItem}
            scrollEnabled={false}
            contentContainerStyle={styles.listContent}
          />
        </View>
      )}

      {/* Empty state */}
      {files.length === 0 && (
        <View style={styles.emptyState}>
          <ThemedText style={{ fontSize: 48 }}>📎</ThemedText>
          <ThemedText type="subtitle" style={{ color: colors.textTertiary, marginTop: Spacing.lg }}>
            No files yet
          </ThemedText>
          <ThemedText style={{ color: colors.textTertiary, marginTop: Spacing.sm, fontSize: 12 }}>
            Share files from your device to get started
          </ThemedText>
        </View>
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
  section: {
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.xl,
  },
  sectionTitle: {
    marginBottom: Spacing.md,
  },
  listContent: {
    gap: Spacing.md,
  },
  fileItem: {
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    borderWidth: 1,
  },
  fileContent: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
  },
  filePreview: {
    width: 60,
    height: 60,
    borderRadius: BorderRadius.md,
  },
  fileIcon: {
    width: 60,
    height: 60,
    borderRadius: BorderRadius.md,
    justifyContent: "center",
    alignItems: "center",
  },
  fileInfo: {
    flex: 1,
    gap: Spacing.xs,
  },
  fileMeta: {
    flexDirection: "row",
    alignItems: "center",
  },
  statusBadge: {
    marginTop: Spacing.xs,
  },
  actions: {
    flexDirection: "row",
    gap: Spacing.md,
  },
  emptyState: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingBottom: 100,
  },
});
