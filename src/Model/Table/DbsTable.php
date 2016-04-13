<?php

namespace App\Model\Table;

use Cake\ORM\Table;
use Cake\Validation\Validator;

class DbsTable extends Table
{
    public function initialize(array $config)
    {
        $this->addBehavior('Timestamp');
    }

    public function validationDefault(Validator $validator)
    {
        $validator
            ->notEmpty('database_name')
            ->notEmpty('purpose')
            ->requirePresence('database_name')
            ->requirePresence('purpose');
        
        $validator->add('database_name', 'unique', [
            'rule' => 'validateUnique',
            'provider' => 'table',
            'message' => 'Sorry - Database names need to be unique across the instance, and that name is already taken..'
        ]);

        return $validator;
    }
}

?>