# PMIDigest

PMIDigest helps summarizing and digesting large sets of publications from PubMed or other sources. It generates an interactive web report which allows revising the articles sorting them by different criteria, classifying in subgroups, highlighting important information or exploring their citation network, among other things.

From the input set of articles, PMIDigest creates a local .html file that can be interatively visualizal with a web browser.

PMIDigest uses cytoscape.js (https://js.cytoscape.org/) and sorttable.js (https://www.kryogenix.org/code/browser/sorttable/).

## 1.- How to use PMIDigest? Step by step guide

### 1.1.- Install PMIDigest on your computer

#### Requirements:

You can install run PMIDigest on Windows, Linux or Mac, with the following requirements:
- PERL must be installed on your computer (https://www.perl.org/).
- WGET must be installed on your computer (https://www.gnu.org/software/wget/).

#### Download PMIDigest:

Download the PMIDigest folder to your computer (for example, by downloading the .zip and extracting it). **Make sure to never move or delete folders and files inside PMIDigest directory or you may experience some problems.**

#### Download MESH database:
- Go to https://nlmpubs.nlm.nih.gov/projects/mesh/MESH_FILES/asciimesh/ and download "d2023.bin" (or its latest version).
- Change the name of this file to "mesh.bin". **Make sure it's lowercased.**
- Place "mesh.bin" inside the "auxiliar_files" folder.

### 1.2.- Retrive the list(s) of papers you want to explore

You must have a list of PubMed papers you want to explore. This must be a plain text file with a PMID (PubMed identifier) on each line. To generate this list at PubMed’s web interface, for example from a search in PubMed’s search engine (https://pubmed.ncbi.nlm.nih.gov/), use the "Save" option and "PMID" as format.

An example of this file is included in the repository ("example_PMIDs").


### 1.3.- Choose the mesh terms you want to highlight

One of the functionalities of PMIDigest is to highlight certain mesh terms relevant for you in your set of paper. This is meant to ease your exploration and give tools to identify relevant information (to learn more, go to "2.2.- Details" and "2.3.- Mesh terms"). 

For that purpose, you can select the categories of mesh terms (technically called "semantic types") you are interested in and associate them to different colors. All terms belonging to given category will be highlighted in that color. Lets say you want all keywords that refer to biological tissues to be highlighted. First, locate that category in the NCBI mesh semantic type (link: https://lhncbc.nlm.nih.gov/ii/tools/MetaMap/Docs/SemGroups_2018.txt). In this case "T024" ("Tissue"). Then, select any color by its color code (RGB, HEX). Create a plain text file in which each line is a semantic type ID ("TXXX") and its associated color separated by a tabulation. You can associate the same color to different categories.

An example of such file is included in the repository ("example_mesh_colors").

### 1.4.- Run PMIDigest.pl
Run in a command shell PMIDigest.pl script with the following command:

	perl PMIDigest.pl your_PMIDs your_mesh_colors your_EMAIL >your_interface.html

Choose whatever name you want as "your_interface.html" as long as it has .html extension. Your email is necessary for performing the NCBI's API.

The execution could take a while. Add the “-v” command line option at the end in order to follow the progress:

	perl PMIDigest.plyour_PMIDs your_mesh_colors your_EMAIL -v >your_interface.html

You can add articles from as many other sources as you want (such as Scopus or Web of Science), by imputing additional .xml files to the command line shown below. You can check which fields need to be included on these files by checking on the example ones on this repository ("example_WoS.xml" and "example_Scopus").

	perl PMIDigest.pl your_PMIDs your_mesh_colors your_EMAIL your_Scopus.xml your_WoS.xml ... >your_interface.html

For example, to generate the example included in the documentation use the following command line:

	perl PMIDigest.pl example_PMIDs.txt example_mesh_colors your@email.com example_WoS.xml example_scopus.xml -v >FoodAdditives.html

This command line will generate this example report http://csbg.cnb.csic.es/jnovoa/PMIDigest/example/FoodAdditives.html.

### 1.5.- PMIDigest is ready to use
Open your new HTML file with your web browser of preference and start using it. Go to "2.- Sections" and "3.- Operations with articles" to learn about PMIDigest functionalities.

### 1.6.- Don't forget to save changes
Use your web browser "Save page" functionality to save the current work session as a HTML file in the work folder. Select "web page, HTML only" option if available. For example, in Firefox, go to "Menu > Save page as" and make sure the "Web Page, HTML only" option is selected. **Make sure you are saving your .html file inside the PMIDigest folder, as this file requires other files from this folder to work.**

To recover a saved session, just open the corresponding HTML file again.
## 2.- Interface sections

The interface is divided in four main sections:

### 2.1.- ARTICLE LIST

_(top-left)_

The table lists all papers within the set, one per row. Click on any row to display the details for this paper in the "Details" section (see below). The fields (columns) are:

-   **"Ref. PMID"**: Reference (Authors. Journal. (Year). Volume (Issue): Pages) and article identifier (e.g. PubMed ID for PubMed entries). Click on the ID to go to the paper's full record in the corresponding resource.
-   **"Source"**: Database from which the article was obtained. PM stands for PubMed.
-   **"Type"**: Publication type:
    -   **R**: Review.
    -   **C**: Clinical or randomized Trial.
    -   **S**: Systematic review or meta-analysis.
-   **"Date"**: Publication date (year.month). Month="00" when only the publication year is known.
-   **"Title"**: Paper title.
-   **"#cit TOT"**: Number of citations in PubMed Central.
-   **"cit/year"**: Ratio between the number of citations and the number of years since publication.
-   **"#cit INT"**: Number of "internal" citations (i.e. citations from other papers within this set).
-   **"Tag"**: Tag assigned by the user to the article. See "Tag papers" below. Empty by default.
-   **"Sel."**: Selection. Allows the user to select one or more papers and operate with them. See below.

The table can be sorted by any field clicking the corresponding column header (press the header again to reverse the sort order). This is useful, for example, to have at the top of the list the highly cited papers, the reviews, the newer articles, ... etc.

### 2.2.- DETAILS

_(top-right)_

This section displays the title and abstract of the selected paper.

Relevant MeSH terms are highlighted coloring them according with the schema specified by the user (see above). Additionally generic terms of interest (either belonging to the MeSH vocabulary or not) can be entered by the user and they will be highlighted in **purple**. (See "3.3.- Enter new highlighted terms" below).

Although MeSH terms are only associated to PubMed articles, instances of them mentioned in articles from other sources are also highlighted. Similarly, for a particular PubMed entry, all mentions in its title/abstract of any MeSH of the whole set are highlighted, irrespective of whether they are indexed for that particular article or not.

This section also includes at the top the reference and the type of article, as well as the article ID, which is a link to the article record in the corresponding database. At the bottom, links to clinical trial databases are included if available, which lead to the corresponding record in these databases with all the details on the clinical trial associated to the publication.

### 2.3.- MeSH TERMS

_(bottom-left)_

This table contain the whole list of MeSH terms associated to the PubMed articles in the set, as well as the terms introduced by the user (See "Enter new highlighted terms" below).

Mesh terms are sorted by their frequencies in the set of articles where they are indexed. The user-introduced terms always appear at the top of the table irrespective of their frequencies. For each term, the following information is shown:

-   **Mesh term ID**, linked to its Entrez page. For user-introduced terms, an internal, not linked, ID is generated.
-   **Term name**, colored according with the criteria described above.
-   **Links to other resources**, only for microorganisms (link to the corresponding NCBI Taxonomy page) and for chemical compounds terms (links to different databases with chemical information). **Empty in other cases.**
-   **Frequency of the term**.
-   **List of papers that include this term**. Click on \[+PMIDs\] to display the complete list and click on \[-pmids\] to collapse it back. Click in any paper ID from the list to show its details in the Details section (see above).

### 2.4.- CITATION NETWORK

_(bottom-right)_

This section shows the network of internal citations between the papers.

Each node represents a paper and each arrow a citation, going from the citing paper to the cited paper. Nodes are colored by the number of internal citations received, from **dark blue** (less) to **yellow** (more). Papers that don't participate in any internal citation (either citing or getting cited) are not included in the network.

Use the mouse wheel to zoom in or out the network. Drag the mouse in the background (outside any node) to pan/move the representation. It is possible to move the nodes to different places dragging them with the mouse. To select a bunch of nodes (e.g. to move them together) draw a box around them dragging the mouse with SHIFT pressed.

You can **left-click** on any node to show the details of the corresponding paper on the Details section (see above). Selected nodes, whose details are shown in the Details Box, are circled in **pink** . You can **right-click** on any node to highlight its connections: **blue** for incoming citations and **red** for outgoing citations. Left-click in any part of the network to undo the highlighting.

It is possible to change the layout of the network (placement of nodes) with the “[+]” menu. Some layouts could slow down the interface when the network is really big.

## 3.- Operations with articles

### 3.1- Tag articles

This functionality allows the user to assign tags to papers. These will be shown in the "Tag" field of the Article List. To tag papers select one or more items from the Article List by checking the corresponding box(es) in the "Sel." column. Then you can either tag these articles as important or use custom tags:

-   Press **"Tag as Imp."** to tag the selected articles as important (Imp.). Rows tagged this way are highlighted with a green background.
-   Press **"Other tags"** to use custom tags. You can enter a name for a new tag in the text box and press the "Tag selection" button to tag selected papers with it. Whenever a new tag is added in this way, it appears in the list of previously created tags and you can select it and press the bottom "Tag selection" button to reuse it in forthcoming tag assignments. **Press "Clear" to delete the tag list.**
-   Press **"Untag"** to delete the tags for the selected papers.

**Note:** You can click in the "Tag" header from the papers table to sort the papers by tag.

### 3.2.- Delete articles

This tool allows the user to (temporary) remove papers from the Article List.

First, select the paper(s) you want to delete by checking the corresponding box(es) in the "Sel." column, and then press **"Del. selection"**. These papers will disappear from the table. To see the list of "deleted" papers, press **"Trash->"**. In this new table you can select deleted papers and press **"Undelete selection"** to move them back to the Article List. Press "<-Return" to leave this deleted papers table and return to the main Article List.

### 3.3- Enter new highlighted terms

This function allows the user to enter new terms that will be highlighted in **purple**.

For that, press **"Enter new terms"** to display a new dialog box and there, write the new terms in the text box. You can enter them one by one, pressing "Add" after writing each of the new terms, or you can enter many at once, separated by ";". You can also delete the list of user terms by pressing "Clear". After making all the changes (either adding or deleting), **you must press "Save changes"**.

Any word that contains one of the user terms will be colored in purple. User terms must be at least three characters long. Terms written in lower case will match either upper case, lower case or mixed, but terms written in upper case will only match upper case. When entering acronyms, it's recommended to write them in upper case, to avoid unwanted matches (e.g. the term "RNA" should be enter in upper case to avoid matching words that contain "rna" such as "alternative").

**Note:** Make sure your new terms are colored in purple in the "Added" list. If not, you might have forgotten to press "Save changes".

### 3.4.- Save session

Use your web browser "Save page" functionality to save the current work session as a HTML file in the work folder. Select "web page, HTML only" option if available. For example, in Firefox, go to "Menu > Save page as" and make sure the "Web Page, HTML only" option is selected.

To recover a saved session, just open the corresponding HTML file.

----------

## Contact

For any problem/question, please contact [jnovoa@cnb.csic.es](mailto:jnovoa@cnb.csic.es) or [pazos@cnb.csic.es](mailto:pazos@cnb.csic.es)

----------
