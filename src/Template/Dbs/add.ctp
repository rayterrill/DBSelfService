<!-- File: src/Template/Articles/add.ctp -->

<h1>Add Database</h1>
<?php
    echo $this->Form->create($db);
    echo $this->Form->input('database_server', array('default' => 'MYDATABASESERVER', 'readonly' => 'readonly'));
    echo $this->Form->input('database_name');
    echo $this->Form->input('purpose');
    echo $this->Form->hidden('owner', array('default' => strtolower($_SERVER['AUTH_USER'])));
    echo $this->Form->button(__('Create Database'));
    echo '<br />NOTE: By default, your AD account will receive db_owner permissions on the newly created database.';
    echo $this->Form->end();
?>