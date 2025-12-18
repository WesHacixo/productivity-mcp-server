# Structured App - Comparison & Research

## Overview

**Structured** is an Apple finalist for best iOS app that is very similar to the original vision of this productivity app. This document captures what we know about Structured and how it relates to our project.

## What We Know About Structured

- **Status**: Apple finalist for best iOS app
- **Platform**: iOS, iPad, Mac, Apple Watch (with Android and Web coming)
- **Developer**: unorderly GmbH
- **Similarity**: Very near to the original idea of this productivity app
- **Core Concept**: Daily planner that integrates calendars, to-do lists, and habit tracking into a **single visual timeline**

### Key Features (from research)

**Core Functionality:**
- **Visual Timeline** - Single unified view combining calendar, tasks, and habits
- **Task Management** - Create, customize, organize tasks
- **Calendar Integration** - Import from Calendar and Reminders (Pro)
- **Habit Tracking** - Track daily habits alongside tasks
- **Recurring Tasks** - Set up repeating tasks (Pro)
- **AI-Powered Scheduling** - Structured AI for smart scheduling (Pro)
- **Notifications** - Customizable task reminders
- **Widgets** - Home screen and lock screen widgets
- **Energy Monitor** - Track energy levels throughout the day

**Platform Support:**
- iPhone, iPad, Mac, Apple Watch
- Future: Android and Web app (via Structured Cloud)

**Accessibility:**
- Full VoiceOver support
- Voice Control support
- Dyslexic-friendly font option
- High contrast mode

**Sync & Cloud:**
- **Structured Cloud** - Proprietary sync solution (replaced iCloud dependency)
- Email-based accounts
- Cross-platform sync (iOS → Android → Web)
- Faster and more reliable than iCloud sync
- APIs available for developers

**Pricing:**
- Free version with essential features
- Structured Pro subscription for advanced features (AI, recurring tasks, calendar import)

**References:**
- [Structured.app](https://structured.app)
- [Structured Cloud Blog Post](https://structured.app/blog/structured-cloud)
- [App Store Listing](https://apps.apple.com/us/app/structured-daily-planner/id1499198946)

## Original Vision of This App

Based on `productivity_tool_app/design.md`, our original vision includes:

### Core Features
1. **Task Management** - List-based with filtering, priorities, subtasks
2. **Time Planning** - Calendar view with time blocks, drag-and-drop scheduling
3. **Goal Tracking** - Long-term goals with milestones and progress rings
4. **File Ingestion** - Share sheet integration, file inbox, parsing capabilities
5. **Home Dashboard** - Today's overview, next time block, active goals

### Key Design Principles
- **One-handed usage** optimization
- **iOS 17 Pro** specific features (Dynamic Island, Action Button)
- **Apple Human Interface Guidelines** compliance
- **Swipe gestures** for quick actions
- **Time blocking** visualization
- **File attachment** to tasks/goals

## Feature Comparison

### ✅ What Structured Has (That We Should Consider)

**Core Features:**
- ✅ **Visual Timeline** - Single unified view (calendar + tasks + habits) - **KEY DIFFERENTIATOR**
- ✅ **Task Management** - Create, customize, organize tasks
- ✅ **Calendar Integration** - Import from system Calendar and Reminders
- ✅ **Habit Tracking** - Daily habits alongside tasks
- ✅ **Recurring Tasks** - Set repeating patterns
- ✅ **AI Scheduling** - AI-powered task scheduling (Pro feature)
- ✅ **Widgets** - Home screen and lock screen widgets
- ✅ **Energy Monitor** - Track energy levels throughout day
- ✅ **Cross-Platform Sync** - Structured Cloud (proprietary solution)
- ✅ **Accessibility** - VoiceOver, Voice Control, dyslexic font

**What We Have (Original Vision):**
- ✅ Task Management with priorities, subtasks, categories
- ✅ Time Planning with calendar view and time blocks
- ✅ Goal Tracking with milestones and progress rings
- ✅ File Ingestion via share sheet (Structured doesn't have this!)
- ✅ Home Dashboard with overview
- ✅ One-handed usage optimization

### 🔍 Key Differences

| Feature | Structured | Our Vision |
|---------|-----------|------------|
| **Primary View** | Visual timeline (calendar + tasks unified) | Separate tabs (Tasks, Time Planning, Goals) |
| **Habit Tracking** | ✅ Built-in | ❌ Not in original design |
| **File Ingestion** | ❌ Not mentioned | ✅ Share sheet, file inbox, parsing |
| **Goal Tracking** | ❌ Not mentioned (habits instead) | ✅ Long-term goals with milestones |
| **AI Features** | ✅ AI scheduling | ✅ AI parsing, subtask generation |
| **Sync Solution** | ✅ Proprietary cloud (Structured Cloud) | ✅ Supabase (PostgreSQL) |
| **Energy Tracking** | ✅ Energy monitor | ❌ Not in original design |
| **Platform** | iOS, Mac, Watch (Android/Web coming) | iOS 17 Pro optimized |

### 🎯 What Makes Structured Award-Winning

1. **Unified Timeline View** - The single visual timeline combining calendar, tasks, and habits is likely the key differentiator. This creates a cohesive daily view rather than separate silos.

2. **Proprietary Sync Solution** - Moving away from iCloud dependency shows technical maturity and control over user experience.

3. **Accessibility Excellence** - Full VoiceOver, Voice Control, and dyslexic-friendly font shows attention to inclusive design.

4. **Cross-Platform Vision** - Planning for Android and Web shows forward-thinking architecture.

5. **Native iOS Integration** - Widgets, Apple Watch support, system calendar integration.

6. **AI Integration** - AI-powered scheduling shows modern feature integration.

## Research Tasks (Updated)

### 1. Feature Comparison ✅
- [x] What task management features does Structured have? - **Timeline-based, recurring, AI scheduling**
- [x] How does Structured handle time planning/blocking? - **Visual timeline (calendar + tasks unified)**
- [x] Does Structured have goal tracking? - **No, but has habit tracking instead**
- [x] What file ingestion capabilities exist? - **Not mentioned in research**
- [x] How does the daily/weekly view work? - **Single visual timeline view**

### 2. UX Patterns
- [ ] Navigation structure and information architecture - **Need to examine app directly**
- [ ] Gesture patterns and interactions - **Need to examine app directly**
- [ ] Visual design and color schemes - **Need to examine app directly**
- [ ] Animation and transitions - **Need to examine app directly**
- [ ] One-handed usage optimizations - **Need to examine app directly**

### 3. Technical Implementation ✅
- [x] Data model and storage approach - **Structured Cloud (proprietary), APIs available**
- [x] Sync mechanisms - **Structured Cloud (email-based accounts, cross-platform)**
- [ ] Performance optimizations - **Need to examine app directly**
- [x] iOS-specific feature usage - **Widgets, Apple Watch, VoiceOver, Voice Control**

### 4. What Makes It Award-Winning ✅
- [x] Unique differentiators - **Unified timeline view, proprietary sync, accessibility**
- [ ] Polished details - **Need to examine app directly**
- [x] User experience innovations - **Visual timeline, AI scheduling, energy monitor**
- [ ] Design excellence - **Need to examine app directly**

## Potential Insights to Apply

Based on Structured being an Apple finalist and our research, we should consider:

### 1. Unified Timeline View (Key Learning)
**Structured's core innovation:** A single visual timeline that combines calendar events, tasks, and habits into one cohesive view. This is likely their main differentiator.

**For Our App:**
- Consider a "Today View" that combines tasks, time blocks, and goals in a single timeline
- Could be an alternative view mode alongside our tab-based navigation
- Visual timeline might be more intuitive than separate tabs

### 2. Proprietary Sync Solution
**Structured's approach:** Built their own cloud sync (Structured Cloud) instead of relying on iCloud, giving them:
- Control over sync reliability
- Cross-platform capability (iOS → Android → Web)
- Faster sync performance
- Ability to address sync issues directly

**For Our App:**
- We're already using Supabase (similar approach - not dependent on iCloud)
- ✅ Good architectural decision
- Consider adding web app support (like Structured is planning)

### 3. Accessibility Excellence
**Structured's commitment:** VoiceOver, Voice Control, dyslexic-friendly font

**For Our App:**
- Ensure full VoiceOver support (already in design doc)
- Consider dyslexic-friendly font option
- Test with Voice Control
- High contrast mode support

### 4. Native iOS Integration
**Structured's features:** Widgets, Apple Watch, system calendar integration

**For Our App:**
- ✅ Already planned: Lock screen widgets, Dynamic Island
- Consider: Apple Watch app, Shortcuts integration, Focus mode integration
- System calendar import (like Structured Pro)

### 5. AI Integration
**Structured's approach:** AI-powered scheduling (Pro feature)

**For Our App:**
- ✅ Already planned: AI parsing, subtask generation
- Consider: AI-powered time block suggestions
- AI productivity analysis (already in design)

### 6. Energy/Habit Tracking
**Structured's feature:** Energy monitor throughout the day

**For Our App:**
- Not in original vision, but could be valuable
- Could integrate with health data
- Consider as future enhancement

### 7. Cross-Platform Vision
**Structured's roadmap:** iOS → Android → Web

**For Our App:**
- Currently iOS-focused (iOS 17 Pro)
- Consider web app for cross-platform access
- Supabase enables this (like Structured Cloud)

## Competitive Advantages We Have

1. **File Ingestion** - Structured doesn't have share sheet file parsing
2. **Goal Tracking** - Structured has habits, we have long-term goals with milestones
3. **MCP Integration** - Claude AI integration via MCP (unique to our app)
4. **Time Block Visualization** - More detailed time planning than timeline view
5. **File Attachments** - Tasks/goals can have file attachments

## Next Steps

### Immediate Actions

1. **✅ Research Structured** - Completed initial research with web scraping
2. **✅ Document Findings** - Feature comparison documented above
3. **✅ Identify Gaps** - Key differences identified (timeline view, habits, energy tracking)
4. **🔄 Prioritize Features** - See recommendations below
5. **⏳ Update Design** - Pending: incorporate learnings into design document

### Recommended Feature Priorities

**High Priority (Aligns with vision, adds value):**
1. **Unified Timeline View** - Add as alternative view mode to our tab-based navigation
2. **System Calendar Import** - Import from iOS Calendar and Reminders
3. **Widgets Enhancement** - Ensure widgets match Structured's quality
4. **Accessibility Polish** - Add dyslexic font option, test Voice Control

**Medium Priority (Nice to have):**
1. **Habit Tracking** - Could complement goal tracking
2. **Energy Monitor** - Interesting but not core to vision
3. **AI Scheduling** - Enhance our AI features with scheduling suggestions

**Low Priority (Different vision):**
1. **Proprietary Cloud** - We're already using Supabase (good choice)
2. **Android/Web** - Future consideration, not immediate

### Design Document Updates Needed

1. Add "Timeline View" as alternative navigation mode
2. Document system calendar import feature
3. Add habit tracking as optional feature
4. Enhance accessibility section with dyslexic font
5. Consider energy tracking integration

## Resources Checked

- ✅ [Structured.app](https://structured.app) - Official website
- ✅ [Structured Cloud Blog Post](https://structured.app/blog/structured-cloud) - Sync solution details
- ✅ [App Store Listing](https://apps.apple.com/us/app/structured-daily-planner/id1499198946) - Features and screenshots
- ✅ Web search results - Feature analysis

## Resources to Check (Future)

- [ ] Download and use the app directly (hands-on experience)
- [ ] App Store reviews (user feedback)
- [ ] YouTube reviews/demos (visual walkthrough)
- [ ] Developer blog posts (technical insights)
- [ ] Social media presence (announcements, updates)
- [ ] Structured APIs documentation (if available)

## Key Takeaways

### What We Learned

1. **Unified Timeline is Key** - Structured's main innovation is the visual timeline combining calendar, tasks, and habits. This is likely what makes it award-winning.

2. **Proprietary Sync Matters** - Building their own cloud sync (instead of iCloud) gives them control and cross-platform capability.

3. **Accessibility is Non-Negotiable** - Full VoiceOver, Voice Control, and dyslexic font show commitment to inclusive design.

4. **Native Integration Wins** - Widgets, Apple Watch, system calendar integration show deep iOS integration.

5. **AI is Expected** - AI-powered scheduling is a Pro feature, showing users expect AI in productivity apps.

### What We Should Keep

- ✅ File ingestion (unique to us)
- ✅ Goal tracking with milestones (more comprehensive than habits)
- ✅ MCP/Claude integration (unique AI integration)
- ✅ Time block visualization (more detailed planning)
- ✅ Supabase architecture (similar to Structured Cloud approach)

### What We Should Consider Adding

- 🔄 Unified timeline view (alternative to tabs)
- 🔄 System calendar import
- 🔄 Habit tracking (complement to goals)
- 🔄 Energy monitor (interesting but not core)
- 🔄 Enhanced accessibility (dyslexic font)

## Notes

- ✅ Initial research completed via web scraping and search
- ✅ Feature comparison documented
- 🔄 Design document updates pending
- 🔄 Hands-on app testing recommended for UX patterns
- Focus on actionable insights, not just feature lists
- Maintain our unique vision while learning from best practices
- Structured's award-winning status likely due to unified timeline + accessibility + native integration
