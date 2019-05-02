This repo demonstrates an issue discovered while using pytest-cov to test
code that imports scikit-learn (sklearn).

Summary: sklearn (joblib, really) spawns a separate Python process because 
it registers a `multiprocessing.Semaphore`. This causes coverage to track 
coverage data from other processes, creating process-specific data files 
that should get combined / cleaned up. This clean-up process does not seem 
to happen when using `pytest-cov`, but it does seem to happen when using 
`coverage run -m pytest`. When a subsequent test command is executed and
coverage is included, those old per-process coverage files are included
in coverage reports and checks (such as line % thresholds). This can cause
incorrect reports and checks, breaking CI and such.

Issue was found using Python 3.6.5 (Anaconda distribution). See requirements.txt and Makefile.

---

How to reproduce the issue: 

```
# also see other make targets in Makefile
make the-issue
```

This runs 2 `pytest` tasks in sequence (with `pytest-cov` enabled), and
prints out files matching the glob `.coverage*`. The first `pytest` task
causes per-process `.coverage` files to linger, affecting the report from
the second `pytest` task.

Example output from my local environment is in `make-the-issue-output.txt`.

An equivalent case using `coverage` and `pytest` (but not `pytest-cov`) can
be executed using `make the-issue-no-pytest-cov`, and shows that the
per-process coverage data files don't linger.


---

Here's a traceback that illustrates what sklearn / joblib is doing that
spawns a separate Python process:

```
    import sklearn as sk
venv/lib/python3.6/site-packages/sklearn/__init__.py:64: in <module>
    from .base import clone
venv/lib/python3.6/site-packages/sklearn/base.py:14: in <module>
    from .utils.fixes import signature
venv/lib/python3.6/site-packages/sklearn/utils/__init__.py:14: in <module>
    from . import _joblib
venv/lib/python3.6/site-packages/sklearn/utils/_joblib.py:22: in <module>
    from ..externals import joblib
venv/lib/python3.6/site-packages/sklearn/externals/joblib/__init__.py:119: in <module>
    from .parallel import Parallel
venv/lib/python3.6/site-packages/sklearn/externals/joblib/parallel.py:22: in <module>
    from ._multiprocessing_helpers import mp
venv/lib/python3.6/site-packages/sklearn/externals/joblib/_multiprocessing_helpers.py:34: in <module>
    _sem = Semaphore()
../../anaconda3/lib/python3.6/multiprocessing/context.py:82: in Semaphore
    return Semaphore(value, ctx=self.get_context())
../../anaconda3/lib/python3.6/multiprocessing/synchronize.py:127: in __init__
    SemLock.__init__(self, SEMAPHORE, value, SEM_VALUE_MAX, ctx=ctx)
../../anaconda3/lib/python3.6/multiprocessing/synchronize.py:81: in __init__
    register(self._semlock.name)
../../anaconda3/lib/python3.6/multiprocessing/semaphore_tracker.py:85: in register
    self._send('REGISTER', name)
../../anaconda3/lib/python3.6/multiprocessing/semaphore_tracker.py:92: in _send
    self.ensure_running()
``` 
