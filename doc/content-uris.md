# Content URIs

Content URIs are at the heart of the kachery system. Files in kachery are never referred to by local file path (e.g., `/path/to/file.dat`) or by web URL (e.g., `http://example.com/file.dat`), but are instead referenced by content URIs of the form

```
sha1://943a702d06f34599aee1f8da8ef9f7296031d699
```

The above 40-character string is the SHA-1 hex digest for the string `"Hello, world!"`. If we are running a kachery node that belongs to a channel containing this string, then we can retrieve this text from the command-line:

```bash
kachery-cat sha1://943a702d06f34599aee1f8da8ef9f7296031d699
# Output: Hello, world!
```

or from Python:

```python
import kachery_client as kc

txt = kc.load_text('sha1://943a702d06f34599aee1f8da8ef9f7296031d699')
print(txt)
# Output: Hello, world!
```

If the kachery channels that our node belongs to do not contain this string, we can add it via:

```python
uri = kc.store_text('Hello, world!')
print(uri)
# Output: sha1://943a702d06f34599aee1f8da8ef9f7296031d699
```

This small string is not very interesting, but the advantages of the content URI scheme start to become evident when we consider larger files. For example, the following is a reference to the plain-text e-book version of *Treasure Island* from Project Gutenberg:

```
sha1://ab42927dabd81c0d7993e369a6a2a1551305aaac/treasure-island.txt
```

(The `treasure-island.txt` part of the string is just for information and does not affect the represented content.)

If we want to count the number of times the word "captain" occurs in this e-book, we can use the following universal script:

```python
import kachery_client as kc

def count_captain(text_uri: str):
    txt = kc.load_text(text_uri)
    word = 'captain'
    return txt.lower().split().count(word)

ct = count_captain('sha1://ab42927dabd81c0d7993e369a6a2a1551305aaac/treasure-island.txt')

print(f'The word "captain" occurs {ct} times in the e-book version of Treasure Island.')

# Output: The word "captain" occurs 102 times in the e-book version of Treasure Island.
```

Now we have a portable script that will always output the same correct result no matter where it is run, assuming that we have access to the file referred to by this URI. In this way we have separated the issue of locating data from the process of specifying a well-defined processing pipeline.

## Pure calculations

A further advantage of this content URI scheme is that it facilitates caching and sharing of *pure calculations*, or calculations that depend only on input arguments and do not read or write to any external state. In kachery we can define a pure calculation function as follows:

```python
import kachery_client as kc

@kc.taskfunction('count_captain.1', type='pure-calculation')
def count_captain(text_uri: str):
    txt = kc.load_text(text_uri)
    word = 'captain'
    return txt.lower().split().count(word)
```

Read more about tasks and pure calculations [here](./tasks.md).