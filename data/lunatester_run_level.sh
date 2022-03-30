#!/bin/bash

wine LunaLoader.exe --testLevel="`winepath --windows \"$1\"`"

