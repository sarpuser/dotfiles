#!/opt/homebrew/bin/python3

import pyperclip
import json
import validators

# Get the argument passed with the keyword (empty string if nothing passed)

clipboard_text = None
match = None
validURL = False

items_dict = {
    'items': [
        {
            'title': '',
            'subtitle': 'Copy to clipboard',
            'arg': '',
            'icon': {
                'path': './icon.png'
            },
            'valid': False,
            'mods': {
                'cmd': {
                    'subtitle': 'Launch in web browser and copy to clipboard'
                }
            }
        }
    ]
}

item = items_dict['items'][0]

try:
    # Check if there's content in the clipboard
    clipboard_text = pyperclip.paste()

    if validators.url(clipboard_text):
        validURL = True
    else:
        item['title'] = 'Clipboard is not a valid URL'

except:
    item['title'] = 'Clipboard empty'


if validURL and 'github.com' in clipboard_text and '/blob/' in clipboard_text:
    # Use clipboard content if no argument provided
    path_elements = clipboard_text.split('/')[3:]
    path_elements.pop(2)
    raw_file_path = 'https://raw.githubusercontent.com/'
    for path in path_elements:
        raw_file_path += path
        raw_file_path += '/'
    raw_file_path = raw_file_path[:-1]
    item['title'] = raw_file_path
    item['arg'] = raw_file_path
    item['valid'] = True
    item['text'] = {
        'copy': raw_file_path,
        'largetype': raw_file_path
    }
else:
    item['title'] = 'Copied URL is not a file on GitHub'
    validURL = False

if not validURL:
    item['subtitle'] = ''
    item['icon'] = {
        'path': './invalid.png'
    }
    item['mods'] = {}

items_json = json.dumps(items_dict)

print (items_json)