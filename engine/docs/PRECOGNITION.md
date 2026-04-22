# Precognition

Precognition is splitting health.attack and health.attack_save into `_precog` and `_enact` parts to use in asynchronous code. All calculations happen in `_precog` in the first frame, basically syncronously. That helps avoid bugs, such as conditions ending before they should affect actions.
