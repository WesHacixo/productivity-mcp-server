export const categoryColors = {
  work: "#0A7EA4",
  personal: "#AF52DE",
  health: "#34C759",
  learning: "#FF9500",
};

export const priorityColors = {
  high: "#FF3B30",
  medium: "#FF9500",
  low: "#34C759",
  minimal: "#8E8E93",
};

export const getCategoryColor = (category: keyof typeof categoryColors): string => {
  return categoryColors[category];
};

export const getPriorityColor = (priority: keyof typeof priorityColors): string => {
  return priorityColors[priority];
};
