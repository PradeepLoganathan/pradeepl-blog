---
title: "Agentic AI: From Copilots to Agents"
lastmod: 2025-09-14T11:21:00+10:00
date: 2025-09-14T11:21:00+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - artificialintelligence
  - agenticai
  - AI
  - machinelearning
  - autonomoussystems
categories:
  - artificialintelligence
  - featured
description: "Explore the revolutionary world of Agentic AI - autonomous systems that can plan, reason, and execute complex tasks with minimal human intervention. Learn how this technology is reshaping the future of AI."
summary: "A comprehensive guide to Agentic AI, exploring how autonomous AI systems are evolving beyond traditional generative AI to become proactive, goal-driven agents capable of complex problem-solving."
ShowToc: true
TocOpen: true
images:
  - "images/agentic-ai-architecture.png"
cover:
    image: "images/agentic-ai-architecture.png"
    alt: "Agentic AI: From Copilots to Agents"
    caption: "The evolution of AI from reactive to proactive systems"
    relative: true
mermaid: true
series: ["Agentic AI"]
---

The artificial intelligence landscape has undergone a remarkable transformation over the past few years, and our exploration of this field has mirrored that evolution. We started with first principles , designed and implemented data architectures, built models, inferred them, and then wired those models into real systems. This post is the natural next step moving onto Agentic AI, where models mature into goal-seeking workers that can plan, use tools, act, and learn inside your environment.

We began by laying data foundations for real-world AI by understanding [Lambda]({{< ref "/blog/lambda-architecture/">}} "What is Artificial Intelligence") and [Kappa architectures]({{< ref "/blog/kappa-architecture/">}}) for batch/stream processing, and then focussing on [Data Mesh]({{< ref "/blog/data-mesh-architecture/">}}) as a means of scaling data ownership and discovery. As our understanding deepened, we looked under the hood at some of the infrastructure that powers modern AI. We investigated specialized databases optimized for [AI workloads with Greenplum]({{< ref "/blog/install-greenplum-windows-wsl/">}}) and learned how to harness GPU acceleration for [TensorFlow on WSL2]({{< ref "/blog/installing-nvidia-cuda-tensorflow-on-windows-wsl2/">}}), understanding that the hardware and data architecture beneath our models are just as crucial as the algorithms themselves.
From those early concepts, we firmed up the conceptual base in the blog post on [Demystifying AI ]({{< ref "/blog/introduction-to-artificial-intelligence">}} "What is Artificial Intelligence"), defining AI and Data Science and surveying core subfields. We then examined how AI models process information and generate responses through [Model Inference]({{< ref "/blog/ai-model-inference-explained/">}}), discovering the critical bridge between trained models and real-world applications. This wasn't just theoretical, We built something tangible, a [fraud-detection model]({{< ref "/blog/building-a-fraud-detection-model/">}} "Fraud detection model") demonstrating how machine learning algorithms can solve tangible business problems through careful data preparation, model training, and deployment.

Most recently, we've witnessed the emergence of a new protocol for AI integration. Through our exploration of the [Model Context Protocol (MCP)]({{< ref "/series/model-context-protocol/">}} "MCP Server Series") we discovered how modern AI systems are breaking free from isolation, connecting to real-world tools, APIs, and data sources. We even [built our own MCP server]({{< ref "/blog/model-context-protocol/build-a-mcp-server/">}} "MCP server"), experiencing firsthand how AI can interact with external systems in standardized, secure ways.

This progression, from understanding AI's core concepts, to implementing practical models, to exploring the infrastructure that supports them, to finally connecting AI systems with the broader digital ecosystem has brought us to an inflection point. We're now ready to explore Agentic AI: the next evolutionary leap where AI systems don't just respond to queries or process data, but actively plan, reason, and execute complex multi-step tasks with minimal human intervention.

This post marks the beginning of a new chapter in our AI exploration series, where we'll discover how the foundational knowledge we've built together naturally evolves into systems capable of independent action and decision-making. Welcome to the era of Agentic AI—where artificial intelligence finally becomes truly autonomous.


## What Makes AI "Agentic"?

The AI revolution, for many, is a story of ever-smarter assistants. First came the chatbots, then the generative models, and most recently, the "copilots"—powerful, single-turn tools that augment human creativity and productivity. But a fundamental shift is underway. We are moving beyond passive, human-prompted models to **autonomous, goal-oriented systems** - what we call **AI agents**.

The AI systems we've built so far in our journey, from the [fraud detection models]({{< ref "/blog/building-a-fraud-detection-model/">}} "Fraud detection model") we built to the [inference servers]({{< ref "/blog/ai-model-inference-explained/">}}) that deploy them, represent what we might call "reactive intelligence." These systems excel at responding to inputs: give them a transaction, and they'll classify it as fraudulent or legitimate; provide them with an image, and they'll identify what's in it; feed them text, and they'll generate a response. But they fundamentally wait for us to provide the input, define the task, and interpret the results.

Agentic AI represents a fundamental shift from this reactive design to proactive, goal-directed systems that can initiate actions, plan sequences of activities, and adapt their approach based on changing circumstances. Where traditional AI systems are like sophisticated calculators waiting for problems to solve, agentic AI systems are more like semi-autonomous colleagues capable of understanding objectives and figuring out how to achieve them. A copilot, no matter how powerful, is a reactive tool; it waits for a human prompt and provides a single, final output. An agent, on the other hand, is proactive. It has a goal, formulates a plan, takes action, and iterates until the goal is achieved. 

## **The LLM as the Brain: A Conceptual Leap**

At the heart of this shift is using a Large Language Model (LLM) not just as a text generator, but as the **reasoning engine** or "brain" of a more complex system. Instead of simply asking an LLM to "write a poem," we task it with a goal like "research and summarize the latest advancements in quantum computing."

The difference is subtle but profound. In the first case, the LLM provides a single-turn completion. In the second, the LLM must:

1. **Deconstruct** the goal into smaller, manageable sub-tasks (e.g., "find recent papers," "extract key findings," "synthesize into a summary").  
2. **Act** on each sub-task, often by using external tools (like a search engine or an API).  
3. **Evaluate** the results of its actions.  
4. **Iterate** on the process, correcting course as needed, until the final summary is produced.

This multi-step reasoning is the core difference between a passive copilot and an active agent. While a simple prompt might ask an LLM to "generate an outline for a blog post," an agent is given the goal "write a blog post about LLM agents." The latter requires a continuous loop of planning, execution, and reflection.

## **The Agentic Loop: Observe, Think, Act**


{{< figure src="images/agentic-loop.png" alt="Agentic Loop" caption="Agentic Loop" >}}


The behavior of an AI agent can be modeled by a continuous feedback loop. While different frameworks use varying terminology, the core cycle remains the same:

1. **Perception (Observe):** The agent takes in new information from its environment. This can be a user's prompt, the output of a tool, a file's content, or a sensor reading. In our simple case, it's the output of the LLM itself after it has "thought" about the problem.  
2. **Planning (Think):** The agent processes the perceived information, formulates a plan, and decides on the next course of action. This is the **LLM-as-a-brain** part, where it reasons about the problem, the available tools, and the current state.  
3. **Action (Act):** The agent executes the planned action. This could be a tool call (e.g., using a search API), writing to a file, or generating a final response to the user.  
4. **Memory:** A crucial but often overlooked component. Memory stores the history of the agent's actions, observations, and thoughts. This allows the agent to maintain context, learn from past mistakes, and avoid repeating work.

## Core Characteristics of Agentic AI

Agentic AI systems are distinguished by several key characteristics that set them apart

**1. Autonomy and Proactivity** : Unlike reactive systems that simply wait for and respond to inputs, agentic AI takes the initiative. These systems are designed to identify opportunities and take iniative. They are designed to act without explicit, step-by-step instructions from a human. They demonstrate a clear goal-directed behavior, striving to achieve defined objectives with minimal human oversight, effectively taking the reins in complex scenarios.
Think about the [fraud detection model]({{< ref "/blog/building-a-fraud-detection-model/">}}) we built. We had to feed it specific transaction data to get a score back. An agentic fraud detection system, on the other hand, would be given a broader goal like: "Proactively monitor our systems and reduce fraudulent transactions by 5% this quarter." It would then act on its own: monitoring data streams, identifying new suspicious patterns, and even suggesting or implementing new security rules without being asked. It owns the objective.

**2. Multi-step Reasoning and Planning** : An agent is a strategist. It can break down a complex objective into a sequence of smaller, manageable steps. It then executes this multi-step plan to achieve objectives. It can also adapt & change plans when circumstances change.
If you gave an agent the goal, "Prepare a market analysis report on our top competitor," it wouldn't just search for one document. It would create a plan:

- Step 1: Search the web for their latest financial reports and news articles.
- Step 2: Access our internal sales database to compare customer overlap.
- Step 3: Analyze social media sentiment using a sentiment analysis tool.
- Step 4: Synthesize all this information into a structured report.

This ability to decompose a problem and create a multi-step plan is what separates it from simple, single-shot generative models.

**3. Tool Use and Integration** : Agents aren't limited to their own knowledge; they can interact with the outside world using tools. This is precisely why our exploration of the [Model Context Protocol (MCP)]({{< ref "/series/model-context-protocol/">}}) is so relevant. An agent's "toolbox" can include:

- Calling APIs (like a weather API or a stock market database).
- Searching the internet.
- Accessing a private database.
- Sending emails or Slack messages.
- Writing and executing its own code.

Agentic AI takes this concept further by not just using tools individually, but by intelligently combining them. It understands which tools are available (building on MCP's capability discovery), can select the right tool for each subtask, and can chain tools together in sophisticated ways.

**4. Context Awareness** : Unlike the stateless nature of many inference systems we've discussed, agentic AI maintains awareness of context across interactions. It remembers previous decisions, learns from outcomes, and adapts its strategies accordingly. This allows it to handle complex, multi-step tasks that require understanding of both the current situation and past actions.

**5. Continuous Learning and Adaptation** :Unlike traditional stateless inference systems, agentic AI is designed to maintain contextual awareness across interactions. It doesn't just respond, it evolves. By remembering past decisions, analyzing outcomes, and integrating feedback, agentic AI continuously refines its behavior and decision-making strategies. 

- Learns from experiences and outcomes : Tracks decisions and their consequences to build a richer understanding over time
- Improves performance over time : Uses accumulated knowledge to enhance accuracy, efficiency, and effectiveness.
- Adapts strategies based on feedback and results : Modifies its approach based on feedback, changing goals, or evolving environments.

## Core Implementation Walkthrough

Let’s ground these ideas in code, using the simplest possible framework-agnostic example to illustrate the conceptual leap from passive LLM calls to agent-like behavior.

### Standard Copilot—Single-Turn LLM Call

First, let's see what a "copilot" call looks like: a passive response model using Akka SDK.

```java
import akka.javasdk.annotations.ComponentId;
import akka.javasdk.client.ComponentClient;
import akka.javasdk.annotations.http.HttpEndpoint;
import akka.javasdk.annotations.http.Post;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.CompletableFuture;
import java.util.List;

@ComponentId("copilot")
@HttpEndpoint("/copilot")
public class CopilotEndpoint {
  private final ComponentClient client;
  private final LLMService llmService;

  public CopilotEndpoint(ComponentClient client, LLMService llmService) {
    this.client = client;
    this.llmService = llmService;
  }

  @Post("/ask")
  public CompletionStage<String> ask(String prompt) {
    return llmService.complete(prompt);
  }
}

class LLMService {
  CompletionStage<String> complete(String prompt) {
    return CompletableFuture.supplyAsync(() -> {
      var request = new ChatRequest(List.of(new Message("user", prompt)));
      return callLLM(request).content();
    });
  }
}
```

This copilot implementation demonstrates the reactive pattern:

- **Stateless**: Each request is independent with no memory of previous interactions
- **Single-turn**: One prompt in, one response out—no planning or iteration
- **Passive**: Waits for explicit user input; cannot initiate actions
- **No Context**: Cannot build on previous conversations or learn from outcomes

While Akka SDK provides the infrastructure for scalability and resilience, this copilot pattern doesn't leverage the actor model's state management capabilities. It's a simple request-response service—powerful for specific tasks, but fundamentally limited in autonomy.
The function 'askLlm' sends the input prompt to the LLM. The OpenAI API is called with a single user message. The LLM responds once, with no persistent state or memory. Each call is stateless: past prompts are not recalled, nor do they influence the next turn. This structure cannot learn, plan, or autonomously continue—a purely reactive system.

### Minimal Agent—Single-Agentic Step Loop

Now, let’s wrap an LLM call in a basic agentic loop. This will:

- Use a **system message** to define the agent’s persona/rules.
- Track **memory** (conversation history).
- Decide, each step, what to do next based on both the last observation and the evolving memory.

```java
// Agent-style: Akka Typed loop with step budget + simple state
import akka.actor.typed.*;
import akka.actor.typed.javadsl.*;

public class MinimalAgent extends AbstractBehavior<MinimalAgent.Msg> {
  interface Msg {}
  public record Start(String goal) implements Msg {}
  public record Observe(String signal) implements Msg {}
  public record Think() implements Msg {}
  public record Act() implements Msg {}

  private final StringBuilder memory = new StringBuilder();
  private final int maxSteps = 5;  // step budget
  private int step = 0;
  private String goal = "";

  public static Behavior<Msg> create() { return Behaviors.setup(MinimalAgent::new); }
  private MinimalAgent(ActorContext<Msg> ctx) { super(ctx); }

  @Override public Receive<Msg> createReceive() {
    return newReceiveBuilder()
      .onMessage(Start.class, this::onStart)
      .onMessage(Observe.class, this::onObserve)
      .onMessage(Think.class, this::onThink)
      .onMessage(Act.class, this::onAct)
      .build();
  }

  private Behavior<Msg> onStart(Start m) {
    this.goal = m.goal;
    getContext().getLog().info("Goal: {}", goal);
    return onObserve(new Observe("init"));
  }

  private Behavior<Msg> onObserve(Observe m) {
    memory.append("OBSERVE: ").append(m.signal).append("\n");
    getContext().getSelf().tell(new Think());
    return this;
  }

  private Behavior<Msg> onThink(Think m) {
    step++;
    // Here you'd call your LLM with (goal + memory) to decide an action.
    String plannedAction = "collect_fact_" + step;
    memory.append("THINK: plan=").append(plannedAction).append("\n");
    getContext().getSelf().tell(new Act());
    return this;
  }

  private Behavior<Msg> onAct(Act m) {
    // Execute the action (tool call); here we just append a fact.
    memory.append("ACT: fact ").append(step).append("\n");
    if (step >= maxSteps /* or goalSatisfied(memory) */) {
      getContext().getLog().info("Agent Task Complete.\n{}", memory);
      return Behaviors.stopped();
    }
    // Loop: observe new signal (could be tool output)
    return onObserve(new Observe("next"));
  }

  public static void main(String[] args) {
    ActorSystem<Msg> system = ActorSystem.create(MinimalAgent.create(), "agent");
    system.tell(new Start("Find five key facts about honey bees"));
  }
}
```

This code implements an agentic AI pattern using Akka Typed actors. It creates a minimal autonomous agent that follows a classic AI agent loop: Observe → Think → Act → Observe.

#### How It Works

1. **Initialization** - The Agent Receives Its Mission

The process starts with a `Start` message containing the agent's goal ("Find five key facts about honey bees"). This critical message establishes the agent's role (autonomous research assistant), its objective (gather five key facts), and the termination rule (stop after 5 steps or when goal satisfied). The actor's internal state is initialized with an empty memory buffer and step counter set to zero.

2. **The Agent Loop: Observe → Think → Act → Observe**:

The code implements a self-messaging pattern where the actor continuously sends messages to itself to maintain an autonomous loop. In each cycle:

- Observe: The actor processes environmental signals through `Observe` messages, appending observations to its memory buffer. This represents the agent's perception capability.

- Think: The actor enters a planning phase where it would integrate with an LLM, passing the current goal and accumulated memory to decide the next action. This is where reasoning and decision-making occurs.

- Act: The actor executes the planned action (currently simulated as collecting facts), appending the results to memory. This represents action execution in the real world.

- Loop Back: After each action, the actor automatically triggers another `Observe` message to continue the cycle.


3. **Memory as Actor State** - Accumulating Agent Experience :

The `StringBuilder memory` serves as the agent's working memory. Unlike conversation history approaches that pass entire context to external services, this Akka Typed implementation maintains state as actor instance variables. Each observation, thought, and action is appended to this memory buffer, providing the agent with :

- Persistence: Memory survives across message processing cycles
- Efficiency: No need to serialize/deserialize entire conversation history
- Type Safety: Memory access is controlled through Akka Typed's message protocol.
- Concurrency Safety: Actor model ensures single-threaded access to memory without locks.

This approach is more efficient than conversation history patterns because the memory stays local to the actor rather than being passed to external services repeatedly.

4. **Termination Condition** - Built-in Step Budget and Goal Satisfaction: 

The loop continues with two termination conditions:

- Step Budget: The agent stops after `maxSteps` (5) iterations to prevent infinite loops, acting as a safety mechanism.
- Goal Satisfaction: The code includes a placeholder `goalSatisfied(memory)` check where you'd implement logic to determine if the objective is complete
- Graceful Shutdown: When termination conditions are met, the actor returns `Behaviors.stopped()`, cleanly shutting down and logging the complete memory contents.

The "agentic" part comes from a few key characteristics:

- **Autonomy**: The AI isn't waiting for a new user prompt at each step. It operates on its own, using the initial goal and its own previous outputs to decide what to do next.
- **Statefulness**: The `conversation` list acts as the agent's memory. By feeding the whole history back to the model each time, the agent "remembers" what it has done, allowing it to count the facts it has found and know when it has reached its goal of five.
- **Goal-Oriented**: The entire process is driven by the initial goal. Each step is an attempt to get closer to fulfilling the task defined in the `system_message`.

Notice the absence of external “tools” here—all “actions” are text completions. In more capable architectures, agents use “tools” (APIs, code execution, database hooks) to interface with the world, but at its core, the agentic loop is about control flow and autonomy, not just the tools used.

#### Core Takeaways from the Implementation

Our minimal agent is a powerful illustration, but it's important to understand its limitations.

- **Naive Memory:** The “memory” is naïvely concatenated messages—it doesn’t scale to large contexts, nor can it manage long-term knowledge efficiently. As mentioned, appending to a list is not a scalable memory solution. Production-grade agents use techniques like sliding window memory, summarization, or offload context to vector databases for long-term recall.
- **No External Grounding:** The agent cannot interact with the outside world. Without external grounding (like APIs or sensors), the agent is still at the mercy of the LLM’s statistical patterns; errors can propagate unchecked. True agency requires the ability to act upon and perceive a real environment.
- **Error Handling:** What if a tool fails? Or the LLM returns a malformed response? A robust agent needs sophisticated error handling, retry mechanisms, and the ability to self-correct its plan when things go wrong.

## Conclusion

We've taken the first crucial step in our journey, moving from passive, single-turn copilots to proactive, autonomous agents. The paradigm shift is not in the LLM itself, but in the architecture we build around it. By wrapping the LLM in an **agentic loop** of **Perception, Planning, Action, and Memory**, we unlock a new class of applications capable of tackling complex, multi-step goals. Our simple akka sdk based java implementation, while basic, reveals the core principles: the power of the **system prompt** to define an agent's purpose, the necessity of **memory** for stateful reasoning, and the **loop** as the engine of autonomy. This foundation sets the stage for the rest of our series, where we will explore adding tools, building robust memory systems, and designing multi-agent architectures.

### What's Next?

Now that we understand what makes AI agents unique - their ability to plan, act, and learn independently - the next big question is: how do we build them in a way that's reliable and scalable? That's where the Akka Actor Model comes in. It offers a fresh approach to handling concurrency and state, which is key for building resilient agents that can work together without stepping on each other's toes.

In the next post, we'll explore why actors -- not traditional threads or shared memory -- are a perfect fit for agentic AI. Plus, I'll walk you through a simple Akka SDK example so you can see these ideas in action.

Ready to see how the foundation of concurrent agents is built? Stay tuned!
As we come to a close, let me leave you with something to consider:

> **If an agent's autonomy is defined by its ability to execute a plan, what is the minimum number of steps required for a system to be considered truly "agentic"?**
