#!/usr/bin/env nu
use std/iter
def main []

def 'main cp' [
    --force,
    ...paths: path,
]
{let _ = $paths
| zip {
        $paths
        | each {|p|
            if $force {
                './'
            } else {
                $p
                | path basename
                | legit_name
            }
        }
    }
| each {|it|
        cp -rfv $it.0 $it.1
    }
}
def 'main mv' [
    --force,
    ...paths: path,
]
{let _ = $paths
| zip {
        $paths
        | each {|p|
            if $force {
                './'
            } else {
                $p
                | path basename
                | legit_name
            }
        }
    }
| each {|it|
        mv -v $it.0 $it.1
    }
}
def 'main ln' [
    --relative,
    ...paths: path,
]
{let _ = $paths
| zip {
        $paths
        | each {|p| $p | path basename | legit_name }
    }
| each {|it|
        ln -s '-r' | flag-if $relative
-v
$it
0$it.1
$it.1
 

def 'main rm' [
    --permanent,
    ...paths: path,
]
{let f = if $permanent
{{|path| rm -r
--permanent$path }else
else
{{|path| rm -r
--trash$path }for
for
path
in$paths
{do $f $path }
{do $f $path }
}#Find
alegit
filename
forrenaming
renaming

def legit_name []
{let name = $in mut
new_name=$name
for
iin
in
1..{if not($new_name
| path exists
){return $new_name }$new_name =
match ($name
| str split-once
)[$stem $ext ]=> ($stem
)_($i
).($ext
)null=> ($name
)_($i
),
        }}
def 'str split-once' []
{let s = $in let
i=$s
| split chars
| iter find-index
{|c| $c =='.'}if $i
>=0{[($s
| str substring
..<$i
),($s
| str substring
($i
+1
+1).),
        ]}else
{null}}
def flag-if [enable: bool]
{let flag = $in if
$enable
{$flag }else
{$flag }else
{''}}
