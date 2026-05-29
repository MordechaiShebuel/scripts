import sys

from odfdo import Document


def odt_to_markdown_optimized(input_file: str, output_file: str):
    """
    Converts ODT to Markdown by recursively walking the document tree.
    """
    markdown_lines = []

    tag_dict = {
        "text:h": {"prefix": "#", "postfix": ""},
        "text:p": {"prefix": "", "postfix": ""},
        "text:list-item": {"prefix": "-", "postfix": ""},
    }

    def walk_elements(element, depth=0):
        """Recursively walks the element tree to find text elements."""
        # Try to get children. Different versions use different names.
        children = []
        if hasattr(element, "get_children"):
            children = element.get_children()
        elif hasattr(element, "children"):
            children = list(element.children)
        elif hasattr(element, "__iter__") and not isinstance(element, str):
            try:
                children = list(element)
            except TypeError:
                children = []
        else:
            children = []

        for child in children:
            tag = getattr(child, "tag", None)

            # If it's a target tag, process it
            if tag in tag_dict:
                content = getattr(child, "text_content", "")
                if isinstance(content, str):
                    content = content.strip()
                else:
                    content = ""

                if content:
                    if tag == "text:h":
                        level = getattr(child, "level", 1)
                        try:
                            level = int(level)
                        except (ValueError, TypeError):
                            level = 1
                        level = max(1, min(6, level))
                        prefix = "#" * level
                        markdown_lines.append(f"{prefix} {content}")
                    elif tag == "text:list-item":
                        markdown_lines.append(f"- {content}")
                    else:
                        markdown_lines.append(content)

            # Recurse into the child to find nested elements
            walk_elements(child, depth + 1)

    try:
        doc = Document(input_file)
        body = doc.body

        # Start walking from the body
        if body:
            walk_elements(body)
        else:
            print("Warning: Document body is empty or None.")

    except FileNotFoundError:
        print(f"❌ Error: File '{input_file}' not found.")
    except Exception as e:
        print(f"❌ Error converting file: {e}")
        import traceback

        traceback.print_exc()
    finally:
        # Write output
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(markdown_lines))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input.odt> <output.md>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    odt_to_markdown_optimized(str(input_path), str(output_path))
