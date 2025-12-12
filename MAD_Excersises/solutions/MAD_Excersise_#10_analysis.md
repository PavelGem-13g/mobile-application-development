# MAD_Excersise #10 – AI and Machine Learning for Mobile Apps

## Block 1 – Role of AI/ML in Mobile Applications

This exercise explores how AI and machine learning algorithms can be integrated into mobile apps to enable intelligent features such as recommendations, personalization, natural language processing, computer vision, and predictive analytics. With the widespread availability of on-device accelerators (Neural Engine, NPUs, GPU) and cloud-based ML services, even small apps can leverage advanced models.

Key motivations for using AI/ML in mobile:
- Personalization: tailoring content, feeds, and recommendations to individual user behavior.
- Automation: smart replies, auto-complete, anomaly detection, and predictive input.
- Perception: computer vision for image classification, object detection, and AR experiences.
- Natural language understanding: chatbots, voice assistants, sentiment analysis.

In your summary, emphasize that AI/ML should solve real user problems—improving usability or value—rather than being added solely for novelty.

---

## Block 2 – Core ML Algorithms and Their Properties

The assignment discusses several ML algorithms (logistic regression, decision trees, random forests, support vector machines, k-nearest neighbors, neural networks, etc.) and compares them in terms of accuracy, training time, inference latency, and resource usage.

High-level characteristics:
- Logistic regression: simple, fast linear model suitable for binary classification (e.g., spam detection, churn prediction); easy to interpret but limited for complex patterns.
- Decision trees and random forests: handle non-linear relationships and feature interactions, robust to outliers; random forests improve generalization via ensembling but can be heavier at inference time.
- Support vector machines (SVMs): powerful for high-dimensional classification, but training can be expensive, and model sizes can be large for mobile deployment.
- K-nearest neighbors (KNN): simple, instance-based method; inference can be slow on-device because it requires storing and scanning many training samples.
- Neural networks and deep learning: highly flexible and accurate for vision and language tasks, at the cost of higher compute and memory requirements.

You should connect these properties to mobile constraints: models must be compact, efficient, and possibly quantized or pruned to run well on typical devices.

---

## Block 3 – On-Device vs Cloud-Based ML

A central design choice is whether to run ML models on-device or offload to cloud services.

On-device ML (e.g., Core ML, TensorFlow Lite, ONNX Runtime):
- Pros: low latency, offline capabilities, improved privacy (data stays on device), reduced server costs.
- Cons: limited by device compute/memory, need to ship and update models within the app, device fragmentation.

Cloud-based ML (e.g., custom APIs, Firebase ML, Azure Cognitive Services, Amazon Rekognition/Comprehend):
- Pros: powerful server-side hardware, easier model updates, ability to aggregate data across users (subject to privacy rules).
- Cons: higher latency, network dependency, ongoing backend costs, and privacy considerations.

The exercise expects you to argue for a hybrid approach for many applications: light on-device models for real-time tasks and cloud inference for heavy workloads or global analytics.

---

## Block 4 – Frameworks and Tooling for Mobile AI

Several frameworks support ML integration on mobile:
- TensorFlow Lite: optimized for running TensorFlow models on Android, iOS, and embedded devices with features like quantization and hardware acceleration.
- Core ML: Apple’s framework for deploying trained models on iOS/macOS, with tight integration into system APIs and tools like Xcode and Create ML.
- ONNX Runtime Mobile: run models in the ONNX format efficiently on various platforms.
- Platform SDKs (ML Kit/Firebase ML, Vision/Language frameworks on iOS): provide ready-made models for common tasks like text recognition, face detection, and translation.

In your analysis, discuss how you would choose between custom models (greater control and flexibility) and pre-built APIs (faster integration, less ML expertise required) for your app scenario.

---

## Block 5 – Responsible AI, Evaluation, and Optimization

Finally, the exercise highlights evaluation metrics and responsible AI considerations.

Important themes:
- Model evaluation: accuracy, precision/recall, F1-score, ROC-AUC, confusion matrices depending on task type.
- Latency and resource usage: measuring inference time and energy impact on representative devices.
- Model optimization: quantization, pruning, knowledge distillation to reduce size and speed up inference.
- Responsible AI: bias, fairness, explainability, and privacy.

For mobile apps, responsible AI means:
- Being transparent about when AI is used and what data is processed.
- Minimizing data collection and using on-device processing where possible.
- Regularly retraining and validating models to avoid degradation and drift.

A short synthesis should explain how careful evaluation and optimization ensure that AI features enhance the user experience instead of degrading performance or trust.

---

## Synthesis / Conclusions

Exercise #10 connects core ML algorithms with practical constraints of mobile platforms. By understanding algorithmic trade-offs and the distinction between on-device and cloud-based inference, you can design AI features that are both powerful and feasible on real devices. Frameworks like TensorFlow Lite and Core ML bridge the gap between data science and app engineering, while platform SDKs accelerate common use cases.

Ultimately, successful mobile AI features depend not only on model accuracy but also on latency, energy efficiency, privacy, and user trust. A disciplined approach to evaluation, optimization, and responsible AI design helps ensure that intelligent features provide tangible value without overwhelming the device or compromising user rights.

