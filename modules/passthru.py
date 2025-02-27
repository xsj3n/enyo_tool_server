import setuptools.dist
from seleniumbase import SB
from time import sleep 
import sys
import re


def remove_ending_number(word):
    w = list(word)
    if not w[-1].isalnum() and re.search("\\d", w[-2]):
        del w[-2]
    elif re.search("\\d", w[-1]):
        del w[-1]
    return "".join(w)
        

query = sys.argv[1]
response_container_selector = 'div[dir="auto"]'
with SB(uc=True, binary_location="/usr/bin/google-chrome-stable", incognito=True) as driver:
    driver.uc_open_with_reconnect("https://www.perplexity.ai/", reconnect_time=3)
    driver.assert_element("textarea", timeout=5)
    driver.uc_click("textarea")
    driver.uc_gui_write(query + "\n")
    driver.assert_element('button[aria-label="Helpful"]', timeout=15)
    words = driver.get_text(response_container_selector).split()
    text = " ".join(map(remove_ending_number, words))
    print(text)
  
