## GitPullDir 

<p align="center">
  <img src="https://github.com/vhanla/gitpulldir/assets/1015823/d3b8fcba-e764-4145-8f94-01d17fc9dfa4" />
</p>

This is just a simple cli tool for Windows to do a `git pull` in each subdirectoy of the current directory which qualifies as a git repository, but for now just checks if it has a `.git` directory inside.

It lists them and proceeds to execute each asking for prompt:

 - y = yes, git pull it
 - n = bypass, continues to the next in queue
 - a = all of them, bypass prompts
 - q = cancel

at the end it shows a list of failed `git pull` calls.
<p align="center">
  <img src="https://github.com/vhanla/gitpulldir/assets/1015823/70c7c089-6f16-4894-b4ea-9b4e4ad3ece0" width="50%"/>
</p>

## DISCLAIMER

Very basic 😅 
