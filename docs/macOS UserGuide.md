# User Guide

### Video Walkthrough
[<img src="https://img.youtube.com/vi/4Q0BduQNcb4/maxresdefault.jpg" width="75%">](https://youtu.be/4Q0BduQNcb4)

## Overview

The main layout is based on a macOs Sidebar Navigation App - which contains 3 panels and should be familiar to all macOS users.

### App Modes / Navigation Tabs
- Browse Mode - used for browsing patches you can download from patchstorage.com
- Library Mode - used to manage patches that have been downloaded from patchstorage.com
- Bank Mode - used to manage banks of 64 patches which are exported in the ZOIA format to be transfered to an SD Card for loading patches on to the ZOIA.

## Discovery and Search Features
- Clicking on any tag adds it a tag filter list in the toolbar. Each tag you click on adds that to the tags searched on patchstorage.com. Remove tags from the filter by clicking on them in toolbar or clicking on the [x] button
- Categories can be filtered using the Category filter list in the Sidebar. Categories are defined by Patchstorage.com - each author can choose which category to associate with their patch.
- Categories are color coded in each patch
- Some of the most common tags are also color coded
- Clicking on an author's name in the Detail View will add that author's name to the search bar.
- The detail view inclides a scrollable description / content field (which can sometimes be quite long) as well as a playbable embedded video if provided by the author.
- Patches can be sorted by Date Modified, Date Submitted, Author, and Title using the dropdown toolbar.
- Patches can be ordered in ascending or descending order using the dropdown in the toolbar.

## Library Features
- Patches can be downloaded to your library by clicking on the download button either in list view or detail view. A patch that is in your library has a check-mark icon. A patch that is in your library but has a new version has a double-square download icon. 
- Currently, only zoia.bin files are supported - if the author has uploaded a different type of file it will show an error icon when downloaded. (.zip files will be supported in a future version).
- The same filtering methods for browse mode also work with patches in your Library
- Patches in your Library can be deleted using the "swipe to delete" gesture common on macOS / iOS or also by simply selecting a patch and hitting the delete key.

## Patch Detail View
- There is a Patch Utilization panel in the detail view which should give a quick reference to the I/O supported by the patch as well as the estimated CPU utilization and number of pages.
- The I/O field labels use a Moog label style - outline is an input - filled is an output. Grey is not used. Blue is used. 
- All pages are shown in the scrollable Detail View. Modules that are named show the name of the module overlaid over the span of buttons for that module.

## Banks
- Banks are used to organize a set of patches for export to the ZOIA
- A Bank contains 64 "slots". A slot can be one of three types:
	- user (or factory) patch
	- blank (or starter) patch
	- empty
- Create a new Bank using the + button in the Sidebar or using the "New Bank" menu command
- You populate a Bank with patches by dragging and dropping patches onto the Bank in the Sidebar. Patches can be dragged from your Library or from another Bank.
- When dragging patches to Banks from the Library, drag the patch image.
- When dragging patches to Banks from other Banks, use the small patch icon.
- Patches within a Bank can also be re-ordered by dragging and dropping the items within the Bank list.
- A slot in a Bank can be turned into a blank patch or empty patch by right-clicking on the desired location in the Bank.
- Banks have a header where you can change the name of the Bank, give it a description and edit the Bank image. You can right-click on the Bank image to choose an icon. YOu can also choose the color of the image. You can also drag-and-drop an image from your computer onto the bank image to use that instead.
- To export a Bank, right-click the Bank and choose "Export". You can also select the Bank and choose the Export menu item in the main menu. Banks are exported to a new folder using the name of the bank.

