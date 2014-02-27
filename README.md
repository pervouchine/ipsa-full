Copyright 2014 Dmitri Pervouchine (dp@crg.eu), Lab Roderic Guigo
Bioinformatics and Genomics Group @ Centre for Genomic Regulation
Parc de Recerca Biomedica: Dr. Aiguader, 88, 08003 Barcelona

This file is a part of the 'ipsa' package.
'ipsa' package is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

'ipsa' package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with 'ipsa' package.  If not, see <http://www.gnu.org/licenses/>.

============================================================================

Integrative pipeline for splicing analyses (IPSA)

1. SYNOPSIS

The integrative pipeline for splicing analyses does:

 * Quantification of splice junctions and splice boundaries
 * Calculation of splicing indices, exon- and intron-centric
 * Analysis of micro-exons and local splice-graph structure

2. DEPENDENCIES

 * maptools (automatic buildout)
 * sjcount (automatic buildout)
 * R-statistics (http://www.r-project.org/)
 * ggplot2 (http://ggplot2.org/)
 * Perl standard modules (http://www.perl.org/)

3. INSTALLATION

	git clone https://github.com/pervouchine/ipsa
	cd ipsa
	make all

4. EXAMPLES

An example of a pipeline buildout is available by running

	make -f example.mk all

5. DOCUMENTATION 

The documentation on the pipeline components is available in latex/ subdirectory
The documentation on the sjcount utility is available in sjcount/latex/ subdirectory

