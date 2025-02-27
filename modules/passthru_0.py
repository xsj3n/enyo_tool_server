import setuptools.dist
import undetected_chromedriver as uc
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver import ActionChains
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from time import sleep 
import sys
import re 

query = sys.argv[1]

driver = uc.Chrome(browser_executable_path="/usr/bin/google-chrome-stable", version_main=132)
wait = WebDriverWait(driver, timeout=10)
driver.get("https://www.perplexity.ai/")

input()
