---
name: react-stable-callbacks
description: Provides the useLatest hook to access the latest values in callbacks without triggering effect re-runs. Use when creating stable callback refs or avoiding stale closures in React components.
---

# React Stable Callback Refs

## When to use this skill
- When you need to access the most recent state or props inside a callback without adding them to a dependency array.
- When an effect is re-running unnecessarily because a function dependency changes every render.
- When you encounter stale closures in asynchronous callbacks or event listeners.

## Implementation

```typescript
import { useRef, useEffect } from 'react'

/**
 * Custom hook to store a value in a ref and keep it updated.
 * Returns a ref object that always points to the latest value passed to the hook.
 */
function useLatest<T>(value: T) {
  const ref = useRef(value)
  useEffect(() => {
    ref.current = value
  }, [value])
  return ref
}
```

## Example Usage

### Correct (Stable Callback Ref)
Use this pattern to ensure `useEffect` only runs once on mount but still has access to the latest prop values.

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  const onSearchLatest = useLatest(onSearch)

  useEffect(() => {
    // This effect runs only once, but always uses the latest onSearch
    const timer = setTimeout(() => {
      onSearchLatest.current("initial search")
    }, 1000)
    return () => clearTimeout(timer)
  }, []) // No dependency needed for onSearchLatest
}
```

### Incorrect (Causes unnecessary re-runs)
Without `useLatest`, adding `onSearch` to the dependency array causes the effect to re-run whenever the parent component re-renders and provides a new function identity.

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  useEffect(() => {
    onSearch("search")
  }, [onSearch]) // If onSearch changes every render, this effect re-runs every render
}
```

## Instructions
1. Copy the `useLatest` implementation into your hooks directory or use it directly.
2. Wrap any frequently changing function or value that is used inside a hook's dependency-free callback.
3. Access the value via `.current` to ensure you have the latest state.
