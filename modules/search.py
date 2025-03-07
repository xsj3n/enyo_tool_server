from seleniumbase import SB
from markdownify import markdownify as md
from selenium.webdriver.common.by import By
import sys 
import urllib.parse

 

search_query = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote_plus(sys.argv[1])
with SB(uc=True, binary_location="/usr/bin/google-chrome-stable", incognito=True, headed=True) as driver:
    driver.uc_open_with_reconnect(search_query, reconnect_time=3)
    driver.assert_element("#links")
    #try:
        #text = driver.find_element("#zero_click_abstract").text
    #    print(text)
    #except:
    #    elements = driver.find_elements(".result")
    #    print(elements)
    href_list = []
    elements = driver.find_elements(By.CSS_SELECTOR, ".result:not(.result--ad)")
    for e in elements[0:3]:
        a_element = e.find_element(By.TAG_NAME, "a")
        
        href = a_element.get_attribute("href")
        #driver.uc_open_with_reconnect(href, reconnect_time=3)
        #driver.assert_element(By.TAG_NAME, "body")
        #body_element = driver.find_element(By.TAG_NAME, "body")
        print("href: " + href + "\n" + "title: " + a_element.text)
        input()

    input()
