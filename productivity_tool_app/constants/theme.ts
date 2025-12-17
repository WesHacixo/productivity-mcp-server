/**
 * Productivity Tool App Theme
 * Optimized for iOS 17 Pro with focus on task management and goal tracking
 */

import { Platform } from "react-native";

// Primary brand colors
const primaryBlue = "#0A7EA4";
const successGreen = "#34C759";
const warningOrange = "#FF9500";
const dangerRed = "#FF3B30";
const neutralGray = "#8E8E93";

// Category colors
const categoryColors = {
  work: primaryBlue,
  personal: "#AF52DE",
  health: successGreen,
  learning: warningOrange,
};

// Priority colors
const priorityColors = {
  high: dangerRed,
  medium: warningOrange,
  low: "#34C759",
  minimal: neutralGray,
};

export const Colors = {
  light: {
    text: "#11181C",
    textSecondary: "#666666",
    textTertiary: "#999999",
    background: "#FFFFFF",
    surface: "#F2F2F7",
    surfaceElevated: "#FFFFFF",
    tint: primaryBlue,
    icon: "#687076",
    tabIconDefault: "#687076",
    tabIconSelected: primaryBlue,
    border: "#E5E5EA",
    success: successGreen,
    warning: warningOrange,
    danger: dangerRed,
    neutral: neutralGray,
  },
  dark: {
    text: "#ECEDEE",
    textSecondary: "#A0A0A0",
    textTertiary: "#707070",
    background: "#000000",
    surface: "#1C1C1E",
    surfaceElevated: "#2C2C2E",
    tint: "#FFFFFF",
    icon: "#9BA1A6",
    tabIconDefault: "#9BA1A6",
    tabIconSelected: "#FFFFFF",
    border: "#3A3A3C",
    success: successGreen,
    warning: warningOrange,
    danger: dangerRed,
    neutral: neutralGray,
  },
};

// Export category and priority colors separately for use in components
export { categoryColors, priorityColors };

export const Fonts = Platform.select({
  ios: {
    sans: "system-ui",
    serif: "ui-serif",
    rounded: "ui-rounded",
    mono: "ui-monospace",
  },
  default: {
    sans: "normal",
    serif: "serif",
    rounded: "normal",
    mono: "monospace",
  },
  web: {
    sans: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    serif: "Georgia, 'Times New Roman', serif",
    rounded: "'SF Pro Rounded', 'Hiragino Maru Gothic ProN', Meiryo, 'MS PGothic', sans-serif",
    mono: "SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace",
  },
});

// Typography scale
export const Typography = {
  title: {
    fontSize: 32,
    lineHeight: 40,
    fontWeight: "bold" as const,
  },
  subtitle: {
    fontSize: 20,
    lineHeight: 28,
    fontWeight: "600" as const,
  },
  body: {
    fontSize: 16,
    lineHeight: 24,
    fontWeight: "400" as const,
  },
  bodySemiBold: {
    fontSize: 16,
    lineHeight: 24,
    fontWeight: "600" as const,
  },
  caption: {
    fontSize: 12,
    lineHeight: 18,
    fontWeight: "400" as const,
  },
  captionSemiBold: {
    fontSize: 12,
    lineHeight: 18,
    fontWeight: "600" as const,
  },
};

// Spacing scale (8pt grid)
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 40,
};

// Border radius
export const BorderRadius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
};

// Shadow
export const Shadows = {
  sm: {
    shadowColor: "#000" as const,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  md: {
    shadowColor: "#000" as const,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
  },
  lg: {
    shadowColor: "#000" as const,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 8,
  },
};

// Helper function to get category color
export const getCategoryColor = (category: keyof typeof categoryColors): string => {
  return categoryColors[category];
};

// Helper function to get priority color
export const getPriorityColor = (priority: keyof typeof priorityColors): string => {
  return priorityColors[priority];
};
