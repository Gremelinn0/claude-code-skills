---
name: infographic
description: Generate professional infographic images in a custom style using the Krea.ai image generation API. Use this skill whenever the user invokes /infographic, wants to create an infographic, diagram, or visual graphic from text content, wants to generate images in a specific style with a logo, or wants to batch-process a multi-section document into multiple infographic images. Triggers on phrases like "create an infographic", "generate a diagram", "make a visual for", "infographic skill", or when the user drops a document and wants visual graphics from it.
version: 1.0.0
---

# Infographic Generator

Generate professional, styled infographic images from text content using the Krea.ai API. Supports logo embedding, style reference images, and batch processing of multi-section documents.

## Prerequisites

### API Key Setup
This skill requires a **Krea.ai API key** stored as an environment variable.

Check if it's already set:
```bash
echo $KREA_API_KEY
```

If empty, ask the user to add it. They can add it to their shell profile or to a `.env` file:
```bash
export KREA_API_KEY="your-krea-api-key-here"
```

The user can get their API key at [krea.ai](https://www.krea.ai) under account settings.

### Optional: Image Hosting (imageb.com)
Krea.ai requires **publicly accessible URLs** for reference images. If the user has a local image (logo, style reference), they need to host it first.

Recommend [imageb.com](https://imageb.com) — free image hosting:
1. Upload the image at imageb.com
2. Copy the public URL
3. Scroll to the bottom of imageb.com to find their API key (if needed for automated uploads)

---

## Workflow

### Step 1: Gather Inputs

Ask the user for:
1. **Content/Topic**: What the infographic should be about (text description, document, or sections)
2. **Style Reference Image URL**: A publicly accessible image URL that defines the visual style (e.g., a superhero graphic, brand template, or design example)
3. **Logo URL** (optional): A publicly accessible URL to a company/brand logo to embed in the graphics
4. **Number of variations**: Default is 5

If any required input is missing, ask for it before proceeding.

### Step 2: Prepare the API Request

Build the Krea.ai image generation request. Use the Python script below:

```python
import os
import requests
import json

KREA_API_KEY = os.environ.get("KREA_API_KEY")
if not KREA_API_KEY:
    raise ValueError("KREA_API_KEY environment variable not set")

def generate_infographic(
    prompt: str,
    style_image_url: str,
    logo_url: str = None,
    num_variations: int = 5
) -> list[str]:
    """Generate infographic images using Krea.ai API."""

    headers = {
        "Authorization": f"Bearer {KREA_API_KEY}",
        "Content-Type": "application/json"
    }

    # Build the enhanced prompt
    full_prompt = f"""
    Create a professional infographic/diagram about: {prompt}

    Style requirements:
    - Match the visual style of the reference image exactly
    - Beautiful and visually appealing layout
    - More diagrammatic and less text-heavy
    - Good balance between illustrations and text
    - Easy to follow along visually
    - Professional and polished look
    """

    if logo_url:
        full_prompt += f"\n- Include the provided logo prominently in the design"

    payload = {
        "prompt": full_prompt,
        "image_guidance_scale": 0.8,  # How closely to follow the style reference
        "num_outputs": num_variations,
    }

    # Add style reference image
    if style_image_url:
        payload["image_url"] = style_image_url

    # Add logo if provided
    if logo_url:
        payload["logo_url"] = logo_url

    # Make the API call
    response = requests.post(
        "https://api.krea.ai/v1/images/generations",
        headers=headers,
        json=payload
    )

    if response.status_code != 200:
        raise Exception(f"Krea.ai API error: {response.status_code} - {response.text}")

    result = response.json()

    # Extract image URLs from response
    image_urls = [img["url"] for img in result.get("images", [])]
    return image_urls

# Example usage
if __name__ == "__main__":
    urls = generate_infographic(
        prompt="Large language models - how Claude works",
        style_image_url="https://example.com/superhero-style.png",
        logo_url="https://example.com/company-logo.png",
        num_variations=5
    )

    for i, url in enumerate(urls, 1):
        print(f"Variation {i}: {url}")
```

### Step 3: Run and Display Results

Execute the script and display all generated image variations. Show them to the user with clear numbering so they can pick their favorite.

If the script fails:
- **401 Unauthorized**: API key is invalid or missing
- **400 Bad Request**: Image URL is not publicly accessible — guide user to use imageb.com
- **429 Too Many Requests**: Rate limit hit — wait a moment and retry

### Step 4: Iterate if Needed

Ask the user for feedback. Common adjustments:
- "Too much cursive text" → Add to prompt: "avoid cursive fonts, use clean sans-serif typography"
- "Too text-heavy" → Add to prompt: "more diagrams and illustrations, minimal text"
- "Need better balance" → Add to prompt: "balanced composition with equal weight on visual elements and text"
- "Different style" → Update the style_image_url with a new reference

---

## Batch Processing (Multi-Section Documents)

If the user drops a document with multiple sections and wants one infographic per section:

1. Parse the document into individual sections
2. For each section, generate `num_variations` images using the same style reference
3. Return all generated images organized by section

```python
def batch_generate_infographics(
    sections: list[str],
    style_image_url: str,
    logo_url: str = None,
    num_variations: int = 1
) -> dict[str, list[str]]:
    """Generate one infographic per section."""
    results = {}

    for i, section in enumerate(sections, 1):
        print(f"Generating infographic for section {i}/{len(sections)}...")
        urls = generate_infographic(
            prompt=section,
            style_image_url=style_image_url,
            logo_url=logo_url,
            num_variations=num_variations
        )
        results[f"Section {i}"] = urls

    return results
```

---

## Example Prompts That Trigger This Skill

- `/infographic Create a diagram on large language models explaining how Claude works, use this superhero style image`
- `Create an infographic for my 5-section document about AI trends`
- `Generate a visual graphic with my company logo in the style of this image`
- `I want 5 variations of an infographic about machine learning basics`

---

## Tips for Best Results

1. **Style reference images**: The more distinct and consistent the style, the better the results. Brand style guides or specific graphic templates work great.

2. **Logo placement**: Krea.ai will attempt to naturally integrate the logo. For best results, use a logo with a transparent background (PNG).

3. **Public URLs**: Always verify that style reference and logo URLs are publicly accessible (not behind login/auth). Use imageb.com if needed.

4. **Prompt quality**: Be specific about the topic and desired visual approach. "Diagrammatic flowchart showing 5 steps" gives better results than "make an infographic".

5. **Batch processing**: For documents, process 1-2 variations per section to keep generation time manageable, then let the user request more for their favorites.
