# Privacy prompts from macOS

The first time you use Artemis, macOS may show a privacy prompt that names
Artemis, such as "Artemis would like to access data from other apps". You
have to answer it before the action it interrupted can finish. There are two
reasons you will see one.

**Artemis itself.** Artemis reads every installed app's signature, and it
writes profiles and launchers into your home folder. It is not sandboxed and
does not have Full Disk Access, so macOS asks before letting it reach
protected locations. Choose Allow if you want the scan and Managed
Applications to work fully. If you choose Don't Allow, Artemis keeps running
but may show less detail for some apps.

**A managed app you launched from Artemis.** macOS holds the launching app
responsible for what the launched app asks for. When a managed app reaches
for something macOS protects (Documents, Desktop, Downloads, another app's
data, the camera and so on), the prompt can name Artemis, or the app's
launcher, and not the app itself. Answer it as if the managed app were
asking, because it is. Allowing it gives that access to anything Artemis
launches, not only that one app.

The seatbelt and these prompts are separate layers. The seatbelt blocks its
list of locations outright, with no prompt. Everything else is still subject
to macOS privacy prompts as usual.

To review or change an answer later, open System Settings > Privacy &
Security and look for Artemis under the relevant category. To be asked
again from scratch, run:

    tccutil reset All com.rgregory.artemis

---
[← Back to the README](../README.md)
