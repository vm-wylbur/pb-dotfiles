<!--
Author: PB & Claude
Maintainer: PB
Original date: 2025.06.30
License: (c) HRDAG, 2025, GPL-2 or newer

------
pdp-CLAUDE.md - Principled Data Processing Guidelines
-->

# Principled Data Processing Guidelines for HRDAG Data Projects

## META GUIDELINES - READ FIRST
**IMPORTANT**: This document works together with two other files to form a complete CLAUDE system:
1. `~/dotfiles/ai/docs/meta-CLAUDE.md` - Common behavioral guidelines for all projects
2. Project-specific `CLAUDE.md` - Requirements specific to this individual project
3. This `pdp-CLAUDE.md` - Data processing methodology for HRDAG data analysis projects

Read all three documents. This document contains only data processing methodology that applies across HRDAG data projects.

## TASK STRUCTURE - HRDAG QUANTUM WORKFLOW

### Standard Task Organization
Every task follows the HRDAG quantum workflow pattern ([detailed explanation](https://hrdag.org/2016/06/14/the-task-is-a-quantum-of-workflow/)) with these directories:
- `input/` - Files the task reads (read-only, from upstream tasks or external sources)
- `src/` - All executable code (R scripts, Python scripts, Makefiles)
- `output/` - Files the task creates (data files, logs, plots, statistics)

### Optional Directories
- `hand/` - Manually maintained data files (lookup tables, constants in YAML)
- `note/` - Jupyter notebooks, R markdown for exploration (not production)
- `docs/` - Documentation from external sources (PDFs, partner docs)
- `frozen/` - Results from interactive tools when no scriptable alternative exists

### Task Naming Convention
Follow pattern: `project/category/source/verb/`
Example: `CO/individual/MOH/import/`, `GT/events/REMHI/clean/`

### Task Self-Documentation
- Task name clearly expresses what it accomplishes
- Directory structure shows input sources and output types
- All transformations documented exclusively through executable code
- No separate documentation files that can become stale

## DATA VALIDATION & TESTING - BLOCKING

### Validation Philosophy
- No formal unit tests, but extensive inline assertions for data validation
- Assertions serve as documentation and catch data anomalies
- Focus on examining specific records that verify expected behavior
- Test both data integrity and business logic expectations

### Assertion Standards
- Write inline assertions liberally - they are documentation, not hidden functions
- Check record counts, key completeness, expected value ranges
- Examine specific records that should meet known criteria
- Validate cross-task consistency (does output match upstream expectations?)

### Task Completion Criteria
A task is complete when:
- All assertions pass during execution
- Expected output files are created
- Manual spot checks confirm expected results
- Makefile runs cleanly with `make` and `make clean`

### Data Format Standards
- Use Parquet files for tabular data (readable by both R and Python)
- Use HDF5 for key-value storage (accessible from both languages)
- Both languages should be able to read each other's output seamlessly

## MAKEFILE REQUIREMENTS - MANDATORY

### Standard Makefile Targets
- Default `make` target runs all processing for the task
- `clean` target removes all files in `output/` directory
- Makefile handles execution sequence within the task
- Use functional names for scripts, let Make handle sequencing

### Multi-Language Support
- Makefile can call both R scripts and Python scripts as needed
- One language per script is typical, but mixing is acceptable
- Scripts should read from `input/` and write to `output/`

## DEVELOPMENT WORKFLOW - DAILY USE

### Task Development Process
- Create task directory structure (`input/`, `src/`, `output/`)
- Place or symlink required inputs
- Write scripts with extensive assertions
- Test execution with `make`
- Verify outputs meet expectations
- Clean and re-run to ensure reproducibility

### Cross-Task Dependencies
- Symlink files from upstream task `output/` to downstream task `input/`
- **CRITICAL: Use only relative paths for symlinks**
- **CRITICAL: All symlinks must stay within project root - no external references**
- Document dependencies clearly in task structure

### Before Moving to Next Task
- Ensure current task runs cleanly with `make`
- Verify all assertions pass
- Confirm outputs are in expected format for downstream consumption

## CODE STANDARDS - DAILY USE

### General Principles
- Keep code **DRY** across tasks
- Follow existing patterns within each language
- Self-documenting code - extensive comments only for business logic
- Assume R uses tidyverse patterns, Python uses modern idioms

### R Standards
- Use tidyverse consistently
- Save data with `write_parquet()` for downstream consumption
- Use meaningful variable names that explain data transformations
- Include `library()` calls at top of each script

### Python Standards
- Use type hints for functions
- Import statements at top in standard 3-group order
- Save data with `pandas.to_parquet()` or appropriate libraries
- Handle errors gracefully with informative messages

### Performance Awareness
- For long-running operations, include progress indicators
- Consider memory usage with large datasets
- Use appropriate data types (factors in R, categories in pandas)

## ERROR HANDLING & LOGGING

### Error Messages
- Make error messages actionable and specific
- Include context about which records or conditions failed
- Log warnings for data anomalies that don't stop processing

### Assertion Failures
- When assertions fail, include enough context to debug the issue
- Show sample records that violate expectations
- Suggest potential causes for common failure patterns

## ANTI-PATTERNS - AVOID THESE

### Harmful Practices (from [HRDAG analysis](https://hrdag.org/2018/02/14/r-projects-and-reports/))
- **Never use .Rproj files** - Creates non-reproducible project dependencies
- **Never use `setwd()`** - Breaks portability across systems
- **Never use `rm(list=ls())`** - False sense of clean environment
- **Never use `attach()`** - Creates namespace pollution
- **Avoid `source()` for data processing** - Use proper input/output files instead

### Data File Management
- **Never commit large data files to git** - Use proper data storage
- **Never use Excel files as primary data format** - Convert to Parquet/HDF5
- **Never embed file paths in scripts** - Use relative paths from task root

## TASK CATEGORIES - COMMON PATTERNS

### Import Tasks
- Initial data ingestion from external sources
- Validation of source data integrity
- Conversion to standard formats (Parquet/HDF5)

### Clean Tasks
- Data standardization and correction
- Handling missing values and outliers
- Ensuring data quality through assertions

### Transform Tasks
- Data reshaping and feature creation
- Merging datasets from multiple sources
- Creating analytical variables

### Analyze Tasks
- Statistical analysis and modeling
- Generating summary statistics
- Creating analytical outputs

### Export Tasks
- Final output generation for reports
- Data formatting for external consumption
- Creating deliverable files