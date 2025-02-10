from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from markdownify import markdownify as md

options = webdriver.FirefoxOptions()
#options.add_argument("-headless")
driver = webdriver.Firefox(options=options)
driver.implicitly_wait(2)

search_query = "what+is+coffee"
driver.get("https://html.duckduckgo.com/html/?q=" + search_query) 

elements = driver.find_elements(By.CLASS_NAME, "result__a")
driver.get(elements[0].get_attribute("href"))

body_element = driver.find_element(By.TAG_NAME, "body")
print(body_element.text)
