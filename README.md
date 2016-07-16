# timing_attack

Profile web applications, sorting inputs into two categories based on
discrepancies in the application's response time.

## Installation

```bash
% gem install timing_attack
```

## Usage

```
timing_attack [options] -a <input> -b <input> -u <target> <inputs>
    -u, --url URL                    URL of endpoint to profile
    -a, --a-example A_EXAMPLE        Known test case that belongs to Group A
    -b, --b-example B_EXAMPLE        Known test case that belongs to Group B
    -n, --number NUM                 Requests per input
        --a-name A_NAME              Name of Group A
        --b-name B_NAME              Name of Group B
    -p, --post                       Use POST, not GET
    -q, --quiet                      Quiet mode (don't display progress bars)
    -v, --version                    Print version information
    -h, --help                       Display this screen
```

**NB**: If the provided examples are invalid, discvery will fail.  Always check
your results!  If very similar inputs are being sorted differently, you may have
used bad training data.

### An example
Consider that we we want to gather information from a Rails server running
locally at `http://localhost:3000`.  Let's say that we know the following:
* `charles@poodles.com` exists in the database
* `invalid@fake.fake` does not exist in the database

And we want to know if `candidate@address.com` and `other@address.com` exist in
the database.

We execute (using `-q` to suppress the progress bar)
```bash
% timing_attack -q -u http://localhost:3000/login \
                -a charles@poodles.com -b invalid@fake.fake \
                candidate@address.com other@address.com
```
```
Group A:
  candidate@address.com         ~0.1969s
Group B:
  other@address.com             ~0.1096s
```
`candidate@address.com` is in the same group as `charles@poodles.com` (Group A),
while `other@address.com` is in Group B with `invalid@fake.fake`
Thus we know that `candidate@address.com` exists in the database, and that
`other@example.com` does not.

To make things a bit friendlier, we can rename groups with the `--a-name` and
`--b-name` options:
```bash
% timing_attack -q -u http://localhost:3000/login \
                -a charles@poodles.com -b invalid@fake.fake \
                --a-name 'Valid logins' --b-name 'Invalid logins' \
                candidate@address.com other@address.com
```
```
Valid logins:
  candidate@address.com         ~0.1988s
Invalid logins:
  other@address.com             ~0.1065s
```

## Contributing

Bug reports and pull requests are welcome [here](https://github.com/ffleming/timing_attack).

## Disclaimer

TimingAttack is quick and dirty.  It is meant to exploit *known* timing attacks based
upon two known values.  TimingAttack is *not* for discovering the existence of
timing-based vulnerabilities.

Also, don't use TimingAttack against machines that aren't yours.

## Todo
* Tests
* Better heuristic than naïve mean comparison
* Auto-discovering heuristic that doesn't require example test cases
* Customizable query parameters
