import { describe, expect, it } from "vitest";
import { categoryColors, priorityColors, getCategoryColor, getPriorityColor } from "../constants/theme-shared";

describe("Theme helpers", () => {
  it("exposes the expected category colors", () => {
    expect(Object.keys(categoryColors)).toEqual(["work", "personal", "health", "learning"]);
    expect(getCategoryColor("work")).toBe(categoryColors.work);
  });

  it("exposes the expected priority colors", () => {
    expect(Object.keys(priorityColors)).toEqual(["high", "medium", "low", "minimal"]);
    expect(getPriorityColor("high")).toBe(priorityColors.high);
  });
});
