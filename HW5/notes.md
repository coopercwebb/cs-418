
# Notes

## Editing-distance explanation

The "editing-distance problem" in computer science is a way to measure how dissimilar two strings of text are from one another. The "distance" is defined as the minimum number of single-character edits required to change one string into the other.

This concept is most famously implemented as the Levenshtein distance.

🎯 The Goal

The core of the problem is to find the smallest number of operations to transform a source string into a target string.

For example, the edit distance between "kitten" and "sitting" is 3. Here is one of the optimal edit sequences:

    kitten → sitten (substitute "k" with "s")

    sitten → sittin (substitute "e" with "i")

    sittin → sitting (insert "g")

⚙️ The Edit Operations

The problem is almost always defined using three basic, "unit-cost" operations (where each operation counts as 1 "point" of distance):

    Insertion: Adding a character to a string.

        Example: "cat" → "cats" (1 insertion)

    Deletion: Removing a character from a string.

        Example: "boat" → "bot" (1 deletion)

    Substitution: Replacing one character with another.

        Example: "book" → "look" (1 substitution)
