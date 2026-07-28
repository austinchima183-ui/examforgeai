# ExamForge AI — Teacher Guide

> **Guide for Teachers Using the Curriculum Content Management System**
> Everything you need to create, manage, and review educational content.

---

## Table of Contents

1. [Overview of the CCMS](#overview-of-the-ccms)
2. [Finding Content by Subject, Level, Topic](#finding-content-by-subject-level-topic)
3. [Creating Questions](#creating-questions)
4. [Using the AI Curriculum Engine](#using-the-ai-curriculum-engine)
5. [Step-by-Step Explanations](#step-by-step-explanations)
6. [Marking Schemes](#marking-schemes)
7. [Content Collections for Lesson Planning](#content-collections-for-lesson-planning)
8. [Reviewing AI-Generated Content](#reviewing-ai-generated-content)
9. [Setting Difficulty Levels and Bloom's Taxonomy](#setting-difficulty-levels-and-blooms-taxonomy)
10. [Curriculum Alignment](#curriculum-alignment)

---

## Overview of the CCMS

The Curriculum Content Management System (CCMS) is ExamForge AI's central platform for creating, organizing, and managing educational content aligned with the Nigerian curriculum. As a teacher, you use the CCMS to:

- **Browse** existing content by subject, level, and topic
- **Create** new questions, explanations, marking schemes, and other content
- **Use AI** to generate content automatically
- **Review** content for quality and accuracy
- **Organize** content into collections for lesson planning
- **Align** content with curriculum standards (NERDC, WAEC, NECO)

### Content Types You Can Create

| Content Type | Description | Example |
|-------------|-------------|---------|
| Question | Assessment questions of various formats | Multiple choice, essay, practical |
| Explanation | Detailed explanation of a concept | "How photosynthesis works" |
| Marking Scheme | Detailed marking allocation | "Question 3: Award 2 marks for..." |
| Teacher Note | Instructional guidance | "Common misconceptions about fractions" |
| Lesson Note | Complete lesson plan | "JSS 2 Mathematics - Week 3" |
| Worksheet | Practice exercise | "Quadratic equation practice problems" |
| Practical Guide | Laboratory or field activity | "Titration experiment procedure" |
| Reading Material | Supplementary reading | "History of Nigerian independence" |
| Video Script | Script for educational video | "Introduction to chemical bonding" |
| Assessment Rubric | Scoring criteria | "Project presentation rubric" |

### Your Dashboard

When you log in, you see the **Teacher Dashboard** with:

- **Content Stats**: How many items you have created, their status (draft/review/published)
- **Pending Reviews**: Content waiting for your review
- **Recent Activity**: Your latest content changes
- **Quick Actions**: Create new content, start AI generation, browse content library

---

## Finding Content by Subject, Level, Topic

### Using the Content Library

The Content Library is your primary tool for browsing and searching content:

1. Navigate to **Content Library** in the sidebar
2. Use the filter panel on the left to narrow results:

| Filter | Description |
|--------|-------------|
| Subject | Filter by subject (e.g., Mathematics, English) |
| Educational Level | Filter by level (e.g., Primary 5, JSS 2, SS 3) |
| Topic | Filter by topic within a subject |
| Content Type | Filter by type (question, explanation, etc.) |
| Difficulty Level | Filter by difficulty |
| Bloom's Level | Filter by cognitive level |
| Status | Draft, Review, Published, Archived |
| Past Question | Show only past exam questions |
| AI Generated | Show only AI-generated content |
| Search | Full-text search across titles and bodies |

### Understanding the Content List

Each content item in the list shows:

- **Title**: The content title
- **Type Badge**: Question, Explanation, etc. (color-coded)
- **Difficulty Badge**: Beginner (green) → Expert (red)
- **Bloom's Level**: Cognitive level indicator
- **Status**: Draft, Review, Published
- **Quality Score**: Average review score (1-5 stars)
- **Usage Count**: How many times this content has been used

### Searching for Content

Use the search bar for full-text search:

- Search works across titles, body text, and explanations
- Use quotes for exact phrases: `"quadratic formula"`
- Combine with filters for precise results
- Results are ordered by relevance and recency

### Viewing Content Details

Click any content item to view its full details:

- **Content body**: The main question or explanation text
- **Options** (for questions): Multiple choice or structured options
- **Correct answer**: The verified correct answer
- **Step-by-step explanation**: Detailed solution walkthrough
- **Marking scheme**: How marks are allocated
- **Teacher notes**: Additional guidance
- **Learning objectives**: Which objectives this content addresses
- **Curriculum references**: Links to curriculum standards
- **Version history**: Previous versions of this content
- **Reviews**: Quality scores and reviewer feedback

---

## Creating Questions

### Question Categories

The CCMS supports a wide range of question formats:

| Category | Description | Example |
|----------|-------------|---------|
| Objective | Multiple choice with single correct answer | "Which planet is closest to the sun? A) Venus B) Mercury C) Mars D) Jupiter" |
| Multiple Choice | Multiple correct answers possible | "Select all prime numbers: A) 2 B) 4 C) 7 D) 9" |
| Theory | Written response required | "Explain the water cycle" |
| Essay | Extended written response | "Discuss the causes and effects of climate change in Nigeria" |
| Practical | Hands-on task | "Perform a titration to determine..." |
| Fill in Blank | Missing word(s) | "The capital of Nigeria is ___" |
| True/False | Binary choice | "Water boils at 100°C at sea level" |
| Matching | Pair related items | "Match the countries with their capitals" |
| Ordering | Arrange in sequence | "Order these events chronologically" |
| Oral | Verbal assessment | "Read the passage aloud with correct pronunciation" |
| Project | Extended project work | "Design an experiment to test..." |

### Creating an Objective Question

1. Navigate to **Content Library** and click **Create Content**
2. Select **Content Type**: Question
3. Select **Question Category**: Objective (or Multiple Choice)
4. Fill in the required fields:

**Basic Information:**
- **Title**: A brief description (e.g., "JSS 2 Math - Solve for x")
- **Subject**: Select the subject
- **Educational Level**: Select the level
- **Topic**: Select the topic
- **Curriculum**: Select the curriculum (NERDC, WAEC, etc.)
- **Difficulty Level**: Beginner, Elementary, Intermediate, Advanced, Expert
- **Bloom's Taxonomy**: Remember, Understand, Apply, Analyze, Evaluate, Create
- **Marks Allocated**: How many marks this question is worth
- **Time Allocated**: Expected time in seconds

**Question Body:**
- Type the question text in the **Body** field
- Use the rich text editor for formatting (bold, italic, subscripts, superscripts)
- For math equations, use LaTeX notation: `$x^2 + 5x + 6 = 0$`

**Answer Options:**
- Click **Add Option** for each choice
- Enter the option label (A, B, C, D) and text
- Mark the correct answer(s)

**Explanation:**
- Provide a **Step-by-Step Explanation** that walks through the solution
- This is essential for student learning and AI review

5. Click **Save as Draft** or **Submit for Review**

### Creating a Theory Question

1. Follow the same steps as above but select **Question Category: Theory**
2. Instead of options, write the question prompt in the **Body** field
3. Provide the expected answer in **Correct Answer** (JSONB format)
4. Write a detailed **Marking Scheme** showing mark allocation:

```json
{
  "total_marks": 10,
  "criteria": [
    {"description": "Correct identification of the concept", "marks": 2},
    {"description": "Accurate explanation with examples", "marks": 4},
    {"description": "Application to real-world scenario", "marks": 2},
    {"description": "Conclusion with critical analysis", "marks": 2}
  ]
}
```

5. Add **Teacher Notes** with guidance on acceptable answers and common mistakes

### Creating a Practical Question

1. Select **Question Category: Practical**
2. Describe the practical activity in the **Body** field
3. Include safety precautions and required materials
4. Provide the expected procedure and observations in the explanation
5. Create a detailed marking scheme for the practical assessment

---

## Using the AI Curriculum Engine

### What the AI Curriculum Engine Does

The AI Curriculum Engine can automatically generate educational content based on:

- Your school's curriculum configuration
- The subject and educational level
- Specific topics and learning objectives
- Desired difficulty and Bloom's taxonomy levels
- Nigerian cultural context

### Generating Content with AI

1. Navigate to **AI Engine** in the sidebar
2. Select the **Subject** and **Educational Level**
3. Optionally select specific **Topics** or **Learning Objectives**
4. Configure generation settings:
   - **Number of Questions**: How many items to generate (1-50)
   - **Question Types**: Objective, Theory, Practical, or mixed
   - **Difficulty Range**: Minimum and maximum difficulty
   - **Bloom's Levels**: Which cognitive levels to target
   - **Include Explanations**: Auto-generate step-by-step solutions
   - **Include Marking Schemes**: Auto-generate marking criteria
5. Click **Generate**

### Generation Process

The AI generation follows these steps:

1. **Analysis**: The engine analyzes the curriculum, topic, and level requirements
2. **Generation**: Content is generated following the configured rules
3. **Validation**: Generated content is checked for:
   - Factual accuracy (basic checks)
   - Age-appropriateness
   - Curriculum alignment
   - Language and cultural sensitivity
4. **Draft Creation**: All AI-generated content is created in **Draft** status

### AI Generation Quality

The AI engine uses your school's configured **Quality Threshold** (default: 3.50):

- Content scoring above the **Auto-Approve Threshold** (default: 4.50) is auto-published
- Content between the quality threshold and auto-approve threshold requires manual review
- Content below the quality threshold is flagged for revision

### Tips for Better AI Generation

1. **Be specific with topics**: Selecting "Quadratic Equations" yields better results than "Algebra"
2. **Set appropriate difficulty**: Match the difficulty to the educational level
3. **Use the right Bloom's levels**: "Remember" and "Understand" for recall questions; "Apply" and "Analyze" for problem-solving
4. **Include explanations**: Always enable explanation generation for student learning
5. **Review all AI content**: AI-generated content should always be reviewed before publishing

---

## Step-by-Step Explanations

### Why Step-by-Step Explanations Matter

Step-by-step explanations are critical for:

- **Student learning**: Students understand not just the answer, but how to arrive at it
- **Self-study**: Enables independent learning outside the classroom
- **AI tutor**: The AI tutor uses explanations to guide students
- **Quality review**: Reviewers can verify the reasoning process

### Writing Effective Explanations

Follow these guidelines for writing clear explanations:

1. **Start from the beginning**: Don't assume prior steps
2. **One step per line**: Break down complex problems into discrete steps
3. **Show all working**: Include intermediate calculations
4. **Explain the reasoning**: Don't just compute — explain why
5. **Highlight common mistakes**: Point out where students typically go wrong

**Example (Mathematics):**

```
Step 1: Write down the equation
  2x + 5 = 15

Step 2: Subtract 5 from both sides to isolate the term with x
  2x + 5 - 5 = 15 - 5
  2x = 10

Step 3: Divide both sides by 2 to solve for x
  2x ÷ 2 = 10 ÷ 2
  x = 5

Step 4: Verify the answer by substituting back
  2(5) + 5 = 10 + 5 = 15 ✓

Common mistake: Some students add 5 instead of subtracting,
getting 2x = 20 and x = 10, which is incorrect.
```

**Example (Biology):**

```
Step 1: Identify the question type
  This asks about the process of photosynthesis.

Step 2: Define photosynthesis
  Photosynthesis is the process by which green plants convert
  sunlight, carbon dioxide, and water into glucose and oxygen.

Step 3: Write the word equation
  Carbon dioxide + Water → Glucose + Oxygen
  (in the presence of sunlight and chlorophyll)

Step 4: Write the chemical equation
  6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂

Step 5: Explain where it occurs
  In the chloroplasts of plant cells, specifically in the
  leaves which contain chlorophyll.
```

---

## Marking Schemes

### Creating a Marking Scheme

A marking scheme specifies how marks are allocated for a question:

**For Objective Questions:**
```json
{
  "method": "exact_match",
  "marks": {"B": 2},
  "negative_marking": false
}
```

**For Theory Questions:**
```json
{
  "method": "criteria_based",
  "total_marks": 10,
  "criteria": [
    {
      "description": "Correct definition of osmosis",
      "marks": 2,
      "keywords": ["movement", "water molecules", "semi-permeable membrane", "region of higher concentration", "lower concentration"]
    },
    {
      "description": "Correct explanation with diagram",
      "marks": 3,
      "notes": "Award 1 extra mark for a clearly labeled diagram"
    },
    {
      "description": "Example from everyday life",
      "marks": 2,
      "examples": ["swelling of raisins in water", "root hair cells absorbing water"]
    },
    {
      "description": "Difference between osmosis and diffusion",
      "marks": 3,
      "key_points": ["osmosis is water only", "diffusion is any substance", "osmosis requires semi-permeable membrane"]
    }
  ]
}
```

### Marking Scheme Best Practices

1. **Total marks should match the allocated marks** for the question
2. **Break down criteria** into clear, assessable components
3. **Include keywords** that should appear in student answers
4. **Provide alternative answers** where multiple valid responses exist
5. **Add notes for markers** about borderline cases
6. **Specify partial credit** rules

---

## Content Collections for Lesson Planning

### Using Collections

Collections help you organize content for specific teaching purposes:

**Common Collection Types:**

| Type | Use Case | Example |
|------|----------|---------|
| Lesson Plan | Content for a single lesson | "JSS 2 Math - Week 5: Fractions" |
| Homework | Practice problems for home | "SS 1 Physics Homework - Forces" |
| Exam | Assessment questions | "Primary 6 English Mid-Term Exam" |
| Revision | Content for exam preparation | "JSS 3 BECE Revision Pack" |
| Custom | Any other purpose | "Difficult Questions Challenge" |

### Creating a Lesson Plan Collection

1. Navigate to **Collections** and click **New Collection**
2. Name it with your lesson details (e.g., "JSS 2 Math - Week 5: Fractions")
3. Set the type to "Lesson Plan"
4. Add content items:
   - Start with an **Explanation** covering the lesson topic
   - Add **Questions** for formative assessment
   - Include a **Worksheet** for practice
   - Add a **Marking Scheme** for the assessment
5. Reorder items to match your lesson flow
6. Make the collection **Public** so other teachers can use it

### Sharing Collections

- **Public collections** are visible to all teachers in your school
- **Private collections** are only visible to you
- You can duplicate public collections from other teachers and customize them

---

## Reviewing AI-Generated Content

### Review Queue

Content submitted for review appears in your **Review Queue**:

1. Navigate to **Content Library** and filter by **Status: Review**
2. You can also filter by **AI Generated** to focus on AI content
3. Click on an item to begin reviewing

### Review Process

For each content item, evaluate and score across four dimensions:

#### 1. Quality Score (1-5)
| Score | Description |
|-------|-------------|
| 1 | Poor: Major formatting or structural issues |
| 2 | Below Average: Several issues that need fixing |
| 3 | Acceptable: Minor issues, generally well-written |
| 4 | Good: Well-written with minimal issues |
| 5 | Excellent: Publication-ready, exemplary quality |

#### 2. Accuracy Score (1-5)
| Score | Description |
|-------|-------------|
| 1 | Incorrect: Factually wrong |
| 2 | Mostly Incorrect: Multiple factual errors |
| 3 | Partially Correct: Some errors or ambiguities |
| 4 | Mostly Correct: Minor inaccuracies |
| 5 | Completely Accurate: No factual errors |

#### 3. Relevance Score (1-5)
| Score | Description |
|-------|-------------|
| 1 | Off-topic: Does not relate to the stated topic |
| 2 | Loosely Related: Tangential connection |
| 3 | Relevant: Covers the topic but may include unnecessary content |
| 4 | Well-Focused: Directly addresses the topic |
| 5 | Perfectly Aligned: Concise and on-point |

#### 4. Curriculum Alignment Score (1-5)
| Score | Description |
|-------|-------------|
| 1 | Not Aligned: Does not match any curriculum objective |
| 2 | Weakly Aligned: Loosely matches objectives |
| 3 | Moderately Aligned: Covers some objectives |
| 4 | Well Aligned: Addresses most objectives |
| 5 | Perfectly Aligned: Directly addresses specific curriculum objectives |

### Review Actions

After scoring, choose one of:

- **Approve**: Content meets standards, change status to Published
- **Request Changes**: Content needs revision, change status to Draft with feedback
- **Reject**: Content is fundamentally flawed (rare; usually Request Changes is preferred)

### Review Comments

Always add constructive comments:

- Point out specific issues with line references
- Suggest concrete improvements
- Highlight what was done well
- For AI content, note any unnatural language or cultural mismatches

---

## Setting Difficulty Levels and Bloom's Taxonomy

### Difficulty Levels

| Level | Description | Typical Use |
|-------|-------------|-------------|
| Beginner | Introductory concepts, basic recall | Early in a topic, lower levels |
| Elementary | Foundational understanding, simple application | Mid-topic, reinforcing basics |
| Intermediate | Standard application, moderate complexity | Most classroom content |
| Advanced | Complex application, multi-step reasoning | Exam preparation, higher levels |
| Expert | Challenging problems, synthesis of concepts | Scholarship-level, competitions |

### Mapping Difficulty to Educational Levels

| Educational Level | Typical Difficulty Range |
|-------------------|------------------------|
| Primary 1-3 | Beginner to Elementary |
| Primary 4-6 | Elementary to Intermediate |
| JSS 1-2 | Elementary to Intermediate |
| JSS 3 | Intermediate to Advanced |
| SS 1 | Intermediate |
| SS 2 | Intermediate to Advanced |
| SS 3 | Advanced to Expert |

### Bloom's Taxonomy Levels

| Level | Cognitive Process | Question Verbs | Example |
|-------|-------------------|---------------|---------|
| Remember | Recall facts and basic concepts | Define, List, Name, Identify | "What is the capital of Nigeria?" |
| Understand | Explain ideas or concepts | Describe, Explain, Summarize | "Explain why water boils at lower temperatures at high altitudes" |
| Apply | Use information in new situations | Solve, Calculate, Demonstrate | "Calculate the area of a triangle with base 8cm and height 5cm" |
| Analyze | Draw connections among ideas | Compare, Contrast, Distinguish | "Compare the economic systems of Nigeria and Ghana" |
| Evaluate | Justify a stand or decision | Assess, Justify, Critique | "Evaluate the effectiveness of Nigeria's environmental policies" |
| Create | Produce new or original work | Design, Construct, Develop | "Design an experiment to test the effect of light on plant growth" |

### Choosing the Right Bloom's Level

When creating content, match the Bloom's level to your teaching objective:

- **Beginning of a topic**: Remember, Understand (build foundational knowledge)
- **Middle of a topic**: Apply, Analyze (develop deeper understanding)
- **End of a topic**: Evaluate, Create (demonstrate mastery)

---

## Curriculum Alignment

### Nigerian Curriculum Bodies

| Body | Full Name | Focus |
|------|-----------|-------|
| NERDC | Nigerian Educational Research and Development Council | Curriculum development for primary and secondary |
| WAEC | West African Examinations Council | SSCE (Senior School Certificate) exams |
| NECO | National Examinations Council | SSCE and BECE (Junior School) exams |
| NABTEB | National Business and Technical Examinations Board | Technical and vocational exams |

### Aligning Content to Curriculum

1. When creating content, select the appropriate **Curriculum** from the dropdown
2. Link the content to specific **Learning Objectives** by their code
3. Add **Curriculum References** in the content metadata:
   ```json
   [
     {"body": "NERDC", "year": 2022, "section": "MATH-SS1-02", "topic": "Quadratic Equations"},
     {"body": "WAEC", "year": 2023, "section": "WASSCE-MATH-3.2"}
   ]
   ```
4. For past questions, set **Is Past Question** = true and enter the **Past Exam Year** and **Past Exam Body**

### Checking Curriculum Coverage

Use the **Curriculum Tree** view to check which learning objectives have content and which are missing:

1. Navigate to **Topics** and select a subject
2. Click **Curriculum Tree** to see the full hierarchy
3. Objectives with content are marked with a green indicator
4. Objectives without content are marked with a red indicator
5. Use this view to identify gaps in your content coverage
