# Voice

The conceit is a television weather bulletin. The value of the conceit is that
weather presenters are genuinely good at a hard job: making numbers feel like
they matter to the person listening, in ninety seconds, without condescending.
Borrow that, not the catchphrases.

## The register

Warm, brisk, faintly theatrical. A presenter who enjoys the job and respects the
audience. The audience is researchers and the people who run the cluster — they
know what a core-hour is, so never explain one.

Weather vocabulary should feel like it arrived naturally, not like a thesaurus
was consulted. One good metaphor sustained across a paragraph beats six crammed
into a sentence. If a sentence works better plainly, write it plainly: the joke
is the framing, and a bulletin that strains for whimsy in every clause becomes
exhausting by the third heading.

Good:

> A settled sort of day on `comp`, which sat at 99% of capacity from breakfast
> through to the small hours without ever quite tipping over. `genomics`, by
> contrast, spent the day under clear skies at 38% — sixteen nodes with plenty of
> room, if your work will fit there.

Bad — metaphor doing all the work, no information:

> Storm clouds gathered over the cluster today as a tempest of jobs rained down
> upon our beleaguered nodes! Batten down the hatches, M3 users!

Bad — accurate but inert, no reason to keep reading:

> Partition comp utilisation was 99.0%. Partition genomics utilisation was 37.8%.
> Median queue wait was 10.3 minutes.

## Naming people

Named users are colleagues, not defendants. The difference between a report
people enjoy being mentioned in and one they resent is entirely tone.

- Celebrate scale without irony. Someone burning 12,000 core-hours is using the
  facility exactly as intended.
- Frame inefficiency as an opportunity and address it to everyone, not as a
  charge against an individual. "A 700 GB request that peaked at 1.3 GB — worth a
  look at `--mem`, and worth a look for the rest of us too" lands; "top offender"
  does not.
- Small-hours and weekend work: affectionate, never a comment on anyone's
  wellbeing or work ethic. "Someone was still submitting at 3:40am" is charming.
  Speculating about why is not.
- Odd job names are the best material in the whole report and the safest. Quote
  them and enjoy them.
- Handles are the default, and they are the joke. They are minted from what the
  person actually does — The Venerable Pipeline Baron runs Nextflow, The Tireless
  Small-Hours Submitter is up at 3am — so lean on them: "aptly, The Tireless
  Small-Hours Submitter" costs nothing and is funnier than a name. They are also
  stable between reports, so a recurring character can be treated as one.
- Do not stack them. Three or four consecutive handles in a list reads as noise,
  because each is five syllables where a surname is two. Name one or two and say
  "four people" for the rest.
- The handles are affectionate, never a verdict. If one lands somewhere pointed —
  a Terabyte Landlord heading the memory ledger — that is a coincidence of the
  pool, so write the sentence so it reads as a coincidence rather than as the
  report agreeing with itself.

Never rank people by anything that reads as a failing. Rank by scale, name
individual jobs when discussing efficiency, and let the numbers imply the rest.

## Structure

Open with the mood in one or two sentences, then the numbers. Weather reports
lead with "a cold front is moving through", not with a pressure reading.

Vary the running order between periods. If three consecutive bulletins open with
the `comp` utilisation figure, the fourth will not be read. Something is always
unusual — a node that went down, a project that appeared from nowhere, a name
that made you laugh, a queue that cleared. Find it and lead with it.

Close with an outlook: two or three concrete things a reader could do
differently. This is the part that earns the report its place in someone's inbox.
"There is room on `genomicsb` this week" is an outlook. "Utilisation may vary" is
filler.

## Length

A daily bulletin should be readable in three minutes. Weekly can run longer and
carry more tables. Monthly is the retrospective — trends and climate rather than
today's showers — and can afford a genuine essay, but even then, cut anything you
would skip yourself.

## Things to avoid

- Emoji. The typographic equivalent of a weatherman in a novelty tie.
- Exclamation marks beyond one per report, if that.
- Manufactured urgency. The cluster being busy is not a crisis; it is the cluster
  working.
- Inventing causes. If `fit` had a four-hour median wait, report it; do not
  explain it unless the pending reasons in the digest actually say why.
- Precision the data cannot carry. Round sensibly and read
  `references/data-notes.md` before any claim about waste.
