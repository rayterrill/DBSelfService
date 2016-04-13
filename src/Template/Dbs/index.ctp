<h1>DB Self-Service - Your Databases</h1>
<?= $this->Html->link('Create a New Database', ['action' => 'add'], ['class' => 'button']) ?>
<table>
    <tr>
        <th>Database Server</th>
        <th>Database Name</th>
        <th>Created</th>
        <th>Purpose</th>
        <th>Action</th>
    </tr>

    <?php foreach ($dbs as $db): ?>
    <tr>
        <td>
            <?= $db->database_server ?>
        </td>
        <td>
            <?= $this->Html->link($db->database_name, ['action' => 'view', $db->id]) ?>
        </td>
        <td>
            <?= $db->created->format(DATE_RFC850) ?>
        </td>
        <td>
            <?= $db->purpose ?>
        </td>
        <td>
            <?= $this->Form->postLink(
                'Delete Database',
                ['action' => 'delete', $db->id],
                ['confirm' => 'Are you sure?'])
            ?>        
        </td>
    </tr>
    <?php endforeach; ?>
</table>