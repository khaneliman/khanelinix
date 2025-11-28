{
  dotnet-validation = ''
    ---
    name: dotnet
    description: "Fast .NET/C# syntax and build validation. Use when checking .cs/.fsproj/.csproj files, fixing compiler errors, or before commits."
    ---

    # .NET Validation

    ## Quick Checks

    ```bash
    # Build check (compiles but no output)
    dotnet build --no-incremental

    # Check specific project
    dotnet build MyProject.csproj

    # Restore and build
    dotnet restore && dotnet build
    ```

    ## Format Check

    ```bash
    # Check formatting (requires dotnet-format or SDK 6+)
    dotnet format --verify-no-changes

    # Format code
    dotnet format

    # Check specific project
    dotnet format MyProject.csproj --verify-no-changes
    ```

    ## Linting

    ```bash
    # Analyzers run during build, treat warnings as errors
    dotnet build -warnaserror

    # Run analyzers only
    dotnet build -p:EnforceCodeStyleInBuild=true
    ```

    ## Testing

    ```bash
    # Run tests
    dotnet test

    # Build tests without running
    dotnet build MyProject.Tests.csproj

    # Test with verbosity
    dotnet test --logger "console;verbosity=detailed"
    ```

    ## Git-Aware

    ```bash
    # Check staged .cs files (limited - dotnet needs project context)
    git diff --cached --name-only | grep -E '\.(cs|fs)$'

    # Find affected projects
    git diff --cached --name-only | grep -E '\.csproj$' | xargs -r -I {} dotnet build {}
    ```

    ## Common Errors

    | Error | Fix |
    |-------|-----|
    | "CS0246: type or namespace not found" | Add using or install NuGet package |
    | "CS1061: does not contain definition" | Check spelling, add using, or cast |
    | "CS0103: name does not exist" | Declare variable or add using |
    | "CS0029: cannot convert type" | Add explicit cast or fix type |
    | "NU1101: unable to find package" | Check NuGet sources, run restore |

    ## Pre-Commit

    ```bash
    dotnet format --verify-no-changes && dotnet build -warnaserror && dotnet test
    ```

    ## Faster Iteration

    ```bash
    # Watch mode
    dotnet watch build

    # Quick syntax check via IDE analyzers
    dotnet build -p:TreatWarningsAsErrors=false -v:q
    ```
  '';
}
