<!-- File: src/Template/Articles/edit.ctp -->

<h1>Edit Db</h1>
<?php
    echo $this->Form->create($db);
    echo $this->Form->input('database_name');
    echo $this->Form->button(__('Save Db'));
    echo $this->Form->end();
?>