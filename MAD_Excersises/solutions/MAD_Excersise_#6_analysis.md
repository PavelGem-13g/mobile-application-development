# MAD_Excersise #6 – Mobile App Performance & Profiling

## Block 1 – Key Performance Metrics

This exercise centers on understanding and improving mobile app performance using profiling tools and metrics. Core metrics include frames per second (FPS), memory footprint, CPU usage, power consumption, responsiveness/input latency, startup time, and garbage collection pauses.

For each metric, you should be able to:
- Define what it measures and why it matters for user experience.
- Identify typical target ranges (e.g., 60 FPS, sub-100 ms input response, reasonable memory bounds).
- Explain how poor values manifest to users (jank, freezes, crashes, rapid battery drain).

This conceptual understanding lets you interpret profiler output and prioritize optimization work.

---

## Block 2 – Profiling Tools Across Platforms

The assignment introduces platform-specific and cross-platform profiling tools.

Android tools:
- Android Profiler (in Android Studio): real-time CPU, memory, and network usage.
- Memory Profiler: heap analysis, allocation tracking, and leak detection.
- CPU Profiler: method-level timings and thread activity.
- Layout Inspector and GPU Rendering Profile: visualizing layout hierarchies and frame rendering.
- System tracing (Perfetto/Systrace): low-level system trace for jank analysis.

iOS tools:
- Xcode Instruments: suite for CPU, memory, disk, and energy profiling.
- Time Profiler: detailed CPU usage per function.
- Allocations & Leaks: memory allocations, retain cycles, and leaks.
- Core Animation template: frame rendering and animation performance.
- Energy Log: battery impact and wake-lock analysis.

Cross-platform tools:
- React DevTools and Flamegraphs for React Native.
- Flutter DevTools: frame timeline, widget rebuilds, memory and CPU.
- APM tools like Firebase Performance, Sentry, DataDog, NewRelic for real-user telemetry.

In your summary, describe which tools you would use for a given type of issue (e.g., slow startup, memory leak, janky scrolling).

---

## Block 3 – Profiling Workflow and Baselines

A good performance optimization process is systematic:
- Define performance goals based on product requirements (e.g., cold start < 3 seconds, scroll smooth at 60 FPS on mid-range devices).
- Establish baselines by profiling typical user journeys on representative devices.
- Record metrics before making changes.
- Use targeted profiles (CPU, memory, network, rendering) to locate bottlenecks.
- Apply small, focused optimizations and re-measure.

In your exercise, you should outline a profiling workflow for a chosen app scenario, including which scenarios to test (app launch, list scrolling, heavy data loading) and which metrics you will track.

---

## Block 4 – Common Performance Bottlenecks and Fixes

Typical sources of performance issues in mobile apps include:
- Main-thread blocking: long database or network operations on the UI thread.
- Overdraw and layout complexity: deeply nested views, unnecessary layouts.
- Excessive object allocation and churn leading to frequent garbage collection.
- Inefficient image handling: loading large bitmaps without downscaling or caching.
- Chatty network usage: many small requests instead of batched calls.

Common optimization strategies:
- Move expensive work off the main thread (coroutines, background queues, async/await).
- Simplify layouts, use constraint-based or composable UIs wisely.
- Pool and reuse objects where appropriate; avoid unnecessary allocations in tight loops.
- Use image loading libraries (Glide, Picasso, Coil, SDWebImage) with proper caching.
- Batch network calls and enable HTTP/2, compression, and caching.

Your analysis should tie specific bottlenecks to profiler evidence and then describe concrete code-level changes.

---

## Block 5 – Memory Leaks, Jank, and Responsiveness

The exercise also covers diagnosing memory leaks and UI jank:
- Memory leaks in Android (e.g., long-lived references to Activities/Views, static singletons holding context) and iOS (retain cycles with strong references and closures).
- Jank from long GC pauses, heavy work in scroll listeners, or inefficient list adapters.
- Frozen UIs from synchronous network or disk access on the main thread.

Explain how tools like LeakCanary (Android), Instruments Leaks (iOS), or DevTools (Flutter/React Native) help detect these issues.

For responsiveness, emphasize design patterns:
- Keep the main thread free for input and rendering.
- Use loaders, skeleton screens, or placeholders to mask unavoidable delays.
- Provide clear feedback for long operations (progress indicators, cancellable tasks).

---

## Block 6 – Performance Testing and Continuous Improvement

Finally, the assignment highlights performance testing and ongoing monitoring:
- Automated performance tests or benchmarks for critical flows.
- Integration of performance checks into CI/CD where feasible.
- Use of real-user monitoring (RUM) tools to track performance in production.

A short reflection should explain how you would define performance budgets for your app and enforce them over time as features grow.

